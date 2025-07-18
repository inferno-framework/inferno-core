module Inferno
  module Web
    module Serializers
      class RequirementsFilteringExtractor < Blueprinter::Extractor
        def extract(_field_name, runnable, local_options, _options)
          if local_options[:suite_requirement_ids].blank?
            runnable.verifies_requirements
          else
            runnable.verifies_requirements.select do |requirement_id|
              local_options[:suite_requirement_ids].include? requirement_id
            end
          end
        end
      end
    end
  end
end
