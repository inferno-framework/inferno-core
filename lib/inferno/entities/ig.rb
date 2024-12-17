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
        :profiles,
        :extensions,
        :value_sets,
        :search_params,
        :examples
      ].freeze

      include Inferno::Entities::Attributes

      def initialize(params)
        super(params, ATTRIBUTES)

        @profiles = []
        @extensions = []
        @value_sets = []
        @examples = []
        @search_params = []
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

        ig = IG.new({})

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
        ig
      end

      def self.from_directory(ig_directory)
        ig = IG.new({})

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
        ig
      end

      # These files aren't FHIR resources
      FILES_TO_SKIP = ['package.json', 'validation-summary.json'].freeze

      def self.skip_item?(relative_path, is_directory)
        return true if is_directory

        file_name = relative_path.split('/').last

        # TODO: consider making these regexes we can iterate over in a single loop
        return true unless file_name.end_with? '.json'
        return true unless relative_path.start_with? 'package/'

        return true if file_name.start_with? '.' # ignore hidden files
        return true if file_name.end_with? '.openapi.json'
        return true if FILES_TO_SKIP.include? file_name

        false
      end

      def handle_resource(resource, relative_path)
        case resource.resourceType
        when 'StructureDefinition'
          if resource.type == 'Extension'
            extensions.push resource
          else
            profiles.push resource
          end
        when 'ValueSet'
          value_sets.push resource
        when 'SearchParameter'
          search_params.push resource
        when 'ImplementationGuide'
          @id = extract_package_id(resource)
        else
          examples.push(resource) if relative_path.start_with? 'package/example'
        end
      end

      def extract_package_id(ig_resource)
        "#{ig_resource.id}##{ig_resource.version || 'current'}"
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
