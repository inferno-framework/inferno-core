# frozen_string_literal: true

module Inferno
  module DSL
    module FHIREvaluation
      module Rules
        class HasExamples < Rule
          def check(_context)
            ''
          end

          def unused_resource_urls
            @unused_resource_urls ||= []
          end

          def used_resources
            @used_resources ||= []
          end

          def get_unused_resource_urls(ig_data, &resource_filter)
            ig_data.each do |resource|
              unused_resource_urls.push resource.url unless resource_filter.call(resource)
            end
          end
        end
      end
    end
  end
end
