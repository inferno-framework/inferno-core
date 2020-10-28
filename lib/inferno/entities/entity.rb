module Inferno
  module Entities
    class Entity
      def initialize(params, attributes)
        attributes.each { |name| instance_variable_set("@#{name}", params[name]) }
      end

      def to_hash
        self.class::ATTRIBUTES.each_with_object({}) do |attribute, hash|
          hash[attribute] = send(attribute)
        end.compact
      end
    end
  end
end
