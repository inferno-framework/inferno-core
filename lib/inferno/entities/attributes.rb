module Inferno
  module Entities
    module Attributes
      def self.included(klass)
        klass.attr_accessor(*klass::ATTRIBUTES)
      end
    end
  end
end
