module Inferno
  module DSL
    module FHIREvaluation
      module DatasetLoader
        def self.from_contents(source_array)
          dataset = []

          source_array.each do |json|
            resource = FHIR::Json.from_json(json)
            next if resource.nil?

            dataset.push resource
          end

          dataset
        end

        def self.from_path(path)
          dataset = []

          Dir["#{path}/*.json"].each do |f|
            resource = FHIR::Json.from_json(File.read(f))
            next if resource.nil?

            dataset.push resource
          end

          dataset
        end
      end
    end
  end
end
