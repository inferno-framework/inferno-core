require 'dry/inflector'
require 'thor'

module Inferno
  module CLI
    class New < Thor::Group
      include Thor::Actions

      desc <<~HELP
        Generate a new Inferno test kit for FHIR
      HELP

      argument :name, type: :string, required: true, desc: 'name for new Inferno project'

      class_option :implementation_guide, aliases: '-i', default: nil, banner: 'IG_URL', desc: 'URL to a FHIR Implementation Guide or path to a package.tgz'

      @@inflector = Dry::Inflector.new do |inflections|
        inflections.acronym 'FHIR'
      end

      def self.source_root
        File.join(__dir__, 'templates')
      end

      def create_app
        @name = name
        @ig = options['implementation-guide']

        ## Template Generation:
        # copies all files from ./templates/ folder
        # performs ERB substitution on all .tt files and removes .tt suffix
        # replaces all %foo% file names with foo() method call
        directory('.', root_name, { mode: :preserve, recursive: true })

        case @ig
        when /^https?/, /^localhost/, /^\d+\.\d+\.\d+\.\d+/
          say 'todo fetch url', color: :blue
        else
          say "If you want to test against a FHIR implementation guide, please copy its package.tgz file into #{File.join(root_name, 'lib', lib_name, 'igs')}", color: :yellow
        end
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
        human_name.split.map{ |s| s.capitalize }.join(' ')
      end

      # suffix '_test_suite' in snake case, i.e: inferno_template_test_suite
      def test_suite_id
        "#{lib_name}_test_suite"
      end
    end
  end
end
