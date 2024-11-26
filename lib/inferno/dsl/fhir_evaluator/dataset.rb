module Inferno
  module DSL
    module FHIREvaluation
      # A Dataset returns an Array of FHIR data to be summarized or evaluated,
      # with convenience methods for loading from a file path or from an
      # Array of FHIR JSON strings.
      module DatasetLoader
        def self.from_contents(source_array)
          dataset = []

          source_array.each do |json|
            resource = FHIR::Json.from_json(json)
            next if resource.nil?

            dataset.push resource
          end

          puts "Loaded #{dataset.length} resources"
          dataset
        end

        def self.from_path(path)
          dataset = []

          Dir["#{path}/*.json"].each do |f|
            resource = FHIR::Json.from_json(File.read(f))
            next if resource.nil?

            dataset.push resource
          end

          puts "Loaded #{dataset.length} resources"
          dataset
        end
      end
    end
  end
end
