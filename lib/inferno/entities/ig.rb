# frozen_string_literal: true

require 'fhir_models'
require 'pathname'
require 'rubygems/package'
require 'zlib'

require_relative '../repositories/igs'

module Inferno
  module Entities
    # IG is a wrapper class around the relevant concepts inside an IG.
    # Not everything within an IG is currently used by Inferno.
    class IG < Entity
      ATTRIBUTES = [
        :id,
        :resources_by_type,
        :examples,
        :source_path
      ].freeze

      include Inferno::Entities::Attributes

      def initialize(**params)
        super(params, ATTRIBUTES)
        @resources_by_type ||= Hash.new { |hash, key| hash[key] = [] }
        @examples = []
      end

      # @param ig_path [String] path to either a `.tgz` IG package or a directory containing an
      #        unpacked one
      # @param standalone_resources_directory [String] optional path to a directory of loose
      #        `*.json` FHIR resource files to merge in alongside the IG, eg author-maintained
      #        resources (extra examples under 'package/example', local overrides) that aren't
      #        part of the IG package itself. Primarily useful for test kit generator scripts.
      # @return [IG]
      def self.from_file(ig_path, standalone_resources_directory: nil)
        raise "#{ig_path} does not exist" unless File.exist?(ig_path)

        # fhir_models by default logs the entire content of non-FHIR files
        # which could be things like a package.json
        original_logger = FHIR.logger
        FHIR.logger = Logger.new('/dev/null')

        ig =
          if File.directory?(ig_path)
            from_directory(ig_path)
          elsif ig_path.end_with? '.tgz'
            from_tgz(ig_path)
          else
            raise "Unable to load #{ig_path} as it does not appear to be a directory or a .tgz file"
          end

        ig.merge_standalone_resources(standalone_resources_directory) if standalone_resources_directory

        ig
      ensure
        FHIR.logger = original_logger if defined? original_logger
      end

      def self.from_tgz(ig_path)
        tar = Gem::Package::TarReader.new(
          Zlib::GzipReader.open(ig_path)
        )

        ig = IG.new

        tar.each do |entry|
          next if skip_item?(entry.full_name, entry.directory?)

          begin
            resource = FHIR::Json.from_json(entry.read)
            next if resource.nil?

            ig.handle_resource(resource, entry.full_name)
          rescue StandardError
            next
          end
        end

        ig.id = extract_package_id(ig.ig_resource)
        ig.source_path = ig_path

        ig
      end

      def self.from_directory(ig_directory)
        ig = IG.new

        ig_path = Pathname.new(ig_directory)
        Dir.glob("#{ig_path}/**/*") do |f|
          relative_path = Pathname.new(f).relative_path_from(ig_path).to_s
          next if skip_item?(relative_path, File.directory?(f))

          begin
            resource = FHIR::Json.from_json(File.read(f))
            next if resource.nil?

            ig.handle_resource(resource, relative_path)
          rescue StandardError
            next
          end
        end

        ig.id = extract_package_id(ig.ig_resource)
        ig.source_path = ig_directory

        ig
      end

      # These files aren't FHIR resources
      FILES_TO_SKIP = ['package.json', 'validation-summary.json'].freeze

      def self.skip_item?(relative_path, is_directory)
        return true if is_directory

        file_name = relative_path.split('/').last

        return true unless file_name.end_with? '.json'
        return true unless relative_path.start_with? 'package/'

        return true if file_name.start_with? '.' # ignore hidden files
        return true if file_name.end_with? '.openapi.json'
        return true if FILES_TO_SKIP.include? file_name

        false
      end

      def handle_resource(resource, relative_path)
        if relative_path.start_with? 'package/example'
          examples << resource
        else
          resources_by_type[resource.resourceType] << resource
        end
      end

      # Merge in loose FHIR resource files from a directory that isn't part of the IG package
      # itself, eg author-maintained resources (extra examples, local SearchParameter overrides,
      # etc) that a test kit generator keeps alongside a downloaded package. Files that aren't
      # valid FHIR resources are skipped. Does nothing if the directory doesn't exist.
      #
      # Files are classified the same way as within an IG package: those under a `package/example`
      # subdirectory are added to {#examples}, everything else (including files directly in
      # `directory`) is added to {#resources_by_type}.
      # @param directory [String] path to a directory of loose `*.json` FHIR resource files,
      #        optionally nested under a `package/example` subdirectory
      # @return [self]
      def merge_standalone_resources(directory)
        return self unless File.directory?(directory)

        base_path = Pathname.new(directory)
        Dir.glob(File.join(directory, '**', '*.json')).each do |file_path|
          relative_path = Pathname.new(file_path).relative_path_from(base_path).to_s

          begin
            resource = FHIR::Json.from_json(File.read(file_path))
            next if resource.nil?
          rescue StandardError
            next
          end

          handle_resource(resource, relative_path)
        end

        self
      end

      def self.extract_package_id(ig_resource)
        "#{ig_resource.id}##{ig_resource.version || 'current'}"
      end

      def value_sets
        resources_by_type['ValueSet']
      end

      def profiles
        resources_by_type['StructureDefinition'].filter { |sd| sd.type != 'Extension' }
      end

      def extensions
        resources_by_type['StructureDefinition'].filter { |sd| sd.type == 'Extension' }
      end

      def capability_statement(mode = 'server')
        resources_by_type['CapabilityStatement'].find do |capability_statement_resource|
          capability_statement_resource.rest.any? { |r| r.mode == mode }
        end
      end

      def ig_resource
        resources_by_type['ImplementationGuide'].first
      end

      def profile_by_url(url)
        profiles.find { |profile| profile.url == url }
      end

      def resource_for_profile(url)
        profiles.find { |profile| profile.url == url }.type
      end

      def value_set_by_url(url)
        resources_by_type['ValueSet'].find { |profile| profile.url == url }
      end

      def code_system_by_url(url)
        resources_by_type['CodeSystem'].find { |system| system.url == url }
      end

      # @private
      def add_self_to_repository
        repository.insert(self)
      end

      # @private
      def repository
        Inferno::Repositories::IGs.new
      end
    end
  end
end
