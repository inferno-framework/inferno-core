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
        :examples
      ].freeze

      include Inferno::Entities::Attributes

      def initialize(**params)
        super(params, ATTRIBUTES)
        @resources_by_type ||= Hash.new { |hash, key| hash[key] = [] }
        @examples = []
      end

      def self.from_file(ig_path)
        raise "#{ig_path} does not exist" unless File.exist?(ig_path)

        # fhir_models by default logs the entire content of non-FHIR files
        # which could be things like a package.json
        original_logger = FHIR.logger
        FHIR.logger = Logger.new('/dev/null')

        if File.directory?(ig_path)
          from_directory(ig_path)
        elsif ig_path.end_with? '.tgz'
          from_tgz(ig_path)
        else
          raise "Unable to load #{ig_path} as it does not appear to be a directory or a .tgz file"
        end
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
