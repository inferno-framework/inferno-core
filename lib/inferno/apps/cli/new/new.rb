require 'dry/inflector'
require 'thor'

module Inferno
  module CLI
    class New
      include Thor::Actions

      @@inflector = Dry::Inflector.new do |inflections|
        inflections.acronym 'FHIR'
      end

      def self.source_root
        File.join(__dir__, 'templates')
      end

      def run(name, implementation_guide = nil)
        @name = name

        ## Template Generation:
        # copies all files from ./templates/ folder
        # performs ERB substitution on all .tt files and removes .tt suffix
        # replaces all %foo% file names with foo() method call
        directory('.', root_name)
        
      end

      # root folder name, i.e: inferno-template
      def root_name
        @@inflector.dasherize(@name)
      end

      # library name, i.e: inferno_template
      def lib_name
        @@inflector.underscore(@name)
      end

      # module name, i.e: InfernoTemplate
      def module_name
        @@inflector.camelize(@name)
      end

      # English grammatical name, i.e: Inferno template
      def human_name
        @@inflector.humanize(@name)
      end

      # title case name, i.e: Inferno Template
      def title_name
        human_name.split(' ').map{ |s| s.capitalize }.join(' ')
      end

      # suffix '_test_suite' in snake case, i.e: inferno_template_test_suite
      def test_suite_id
        "#{lib_name}_test_suite"
      end
    end
  end
end
