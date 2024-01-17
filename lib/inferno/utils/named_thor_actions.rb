require 'dry/inflector'

module Inferno
  module Utils
    module NamedThorActions
      INFLECTOR = Dry::Inflector.new

      def root_name
        INFLECTOR.dasherize(INFLECTOR.underscore(name))
      end

      def library_name
        INFLECTOR.underscore(name)
      end

      def module_name
        INFLECTOR.camelize(name)
      end

      def human_name
        INFLECTOR.humanize(INFLECTOR.underscore(name))
      end

      def title_name
        human_name.split.map(&:capitalize).join(' ')
      end

      def test_suite_id
        "#{library_name}_test_suite"
      end
    end
  end
end
