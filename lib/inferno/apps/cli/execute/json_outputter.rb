require 'active_support'
require_relative '../../web/serializers/test_run'
require_relative '../../web/serializers/result'

module Inferno
  module CLI
    class Execute
      # @private
      class JSONOutputter
        def print_start_message(_options); end

        def print_around_run(_options, &)
          yield
        end

        def print_results(_options, results)
          puts serialize(results)
        end

        def print_end_message(_options); end

        def print_error(_options, exception)
          puts exception.to_json
        end

        def serialize(entity)
          case entity.class.to_s
          when 'Array'
            JSON.pretty_generate(entity.map { |item| JSON.parse serialize(item) })
          else
            Inferno::Web::Serializers.const_get(entity.class.to_s.demodulize).render(entity)
          end
        end
      end
    end
  end
end
