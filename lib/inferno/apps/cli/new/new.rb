require 'dry/inflector'
require 'faraday'
require 'fileutils'
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
        @ig_url = options['implementation_guide']

        ## Template Generation:
        # copies all files from ./templates/ folder
        # performs ERB substitution on all .tt files and removes .tt suffix
        # replaces all %foo% file names with foo() method call
        directory('.', root_name, { mode: :preserve, recursive: true })

        case @ig_url
        when /^https?:\/\//
          
          response = Faraday.get(@ig_url)
          if response.status == 200
            create_file(ig_file, response.body)
          else
            say "Failed to load #{@ig_url}", :red
            say "Please add the implementation guide package.tgz file into #{ig_path}", :red
          end
        when /^file:/
          @ig_url.rchomp! 'file:'.reverse # TODO test
          begin
            FileUtils.cp(@ig_url, ig_file)
          rescue
            say "Failed to load #{@ig_url}", :red
            say "Please add the implementation guide package.tgz file into #{ig_path}", :red
          end
        else
          say "If you want to test against an implementation guide, add its package.tgz file into #{ig_path}"
        end

        say "Successfully created #{root_name} test kit!", :green
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

      # path to where package.tgz should reside, i.e: lib/inferno_template/igs
      def ig_path
        File.join('lib', lib_name, 'igs')
      end

      # path to package.tgz including file, i.e: lib/inferno_template/igs/package.tgz
      def ig_file
        File.join( ig_path, 'package.tgz' )
      end
    end
  end
end
