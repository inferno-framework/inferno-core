require 'active_support'
require_relative '../../web/serializers/test_run'
require_relative '../../web/serializers/result'

module Inferno
  module CLI
    class Execute
      # @private
      module Serialize
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
