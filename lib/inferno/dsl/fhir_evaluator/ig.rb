# frozen_string_literal: true

require 'rubygems/package'
require 'zlib'

module FhirEvaluator
  # IG is a wrapper class around the relevant concepts inside an IG.
  # Not everything within an IG is relevant to the evaluation this tool does.
  class IG
    attr_accessor :profiles, :extensions, :value_sets, :search_params, :examples

    def initialize(ig_path)
      raise "#{ig_path} is not an IG file" unless File.file?(ig_path)

      @profiles = []
      @extensions = []
      @value_sets = []
      @examples = []
      @search_params = []

      tar = Gem::Package::TarReader.new(
        Zlib::GzipReader.open(ig_path)
      )

      # fhir_models by default logs the entire content of non-FHIR files
      # which could be things like a package.json
      original_logger = FHIR.logger
      FHIR.logger = Logger.new('/dev/null')

      tar.each do |entry|
        next if skip_tar_entry? entry

        begin
          resource = FHIR::Json.from_json(entry.read)
          next if resource.nil?

          handle_resource(resource, entry)
        rescue StandardError
          next
        end
      end

      FHIR.logger = original_logger

      puts 'Loaded ' \
           "#{profiles.length} profiles, " \
           "#{extensions.length} extensions, " \
           "#{value_sets.length} value sets, " \
           "#{examples.length} examples from #{ig_path} \n\n"
    end

    private

    # These files aren't FHIR resources
    FILES_TO_SKIP = ['package.json', 'validation-summary.json'].freeze

    def skip_tar_entry?(entry)
      return true if entry.directory?

      file_name = entry.full_name.split('/').last

      # TODO: consider making these regexes we can iterate over in a single loop
      return true unless file_name.end_with? '.json'
      return true unless entry.full_name.start_with? 'package/'

      return true if file_name.start_with? '.' # ignore hidden files
      return true if file_name.end_with? '.openapi.json'
      return true if FILES_TO_SKIP.include? file_name

      false
    end

    def handle_resource(resource, entry)
      if resource.resourceType == 'StructureDefinition'
        if resource.type == 'Extension'
          extensions.push resource
        else
          profiles.push resource
        end
      elsif resource.resourceType == 'ValueSet'
        value_sets.push resource
      elsif resource.resourceType == 'SearchParameter'
        search_params.push resource
      elsif entry.full_name.start_with? 'package/example'
        examples.push resource
      end
    end
  end
end
