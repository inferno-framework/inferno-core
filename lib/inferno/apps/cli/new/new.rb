require 'dry/inflector'
require 'thor'

module Inferno
  module CLI
    class New < Thor
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
        # performs ERB substitution on all .tt files and remove .tt suffix
        # replaces all %foo% file names with foo() method call
        directory('.', root_name)
        
      end

      # root folder name, i.e: inferno-template
      def root_name
        @@inflector.dasherize(@name)
      end

      # lib folder name, i.e: inferno_template
      def lib_name
        @@inflector.underscore(@name)
      end

      # file name with suffix extension, i.e: inferno_template.rb
      def file_name(suffix = '.rb')
        @@inflector.underscore(@name) + suffix
      end

      # module name, i.e: InfernoTemplate
      def module_name
        @@inflector.camelize(@name)
      end

      # English grammatical name, i.e: Inferno template
      def human_name
        @@inflector.humanize(@name)
      end
    end
  end
end
