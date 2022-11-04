module Inferno
  module Entities
    # @private
    module Attributes
      def self.included(klass)
        klass.attr_accessor(*klass::ATTRIBUTES)
      end
    end
  end
end
