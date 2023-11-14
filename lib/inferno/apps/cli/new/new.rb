require 'dry/inflector'
require 'faraday'
require 'fileutils'
require 'thor'

module Inferno
  module CLI
    class New < Thor::Group
      include Thor::Actions

      desc <<~HELP
        Generate a new Inferno test kit for FHIR software testing

        https://github.com/inferno-framework
      HELP

      argument :name,
               type: :string,
               required: true,
               desc: 'name for new Inferno project'
      class_option :implementation_guide,
                   type: :string,
                   aliases: '-i',
                   default: nil,
                   banner: 'IG_URL',
                   desc: 'URL to a FHIR Implementation Guide or path to a package.tgz'
      class_option :author,
                   type: :string,
                   aliases: '-a',
                   default: fetch_user(),
                   repeatable: true,
                   desc: 'Author names for *.gemspec file; you can specify this more than once'

      @@inflector = Dry::Inflector.new do |inflections|
        inflections.acronym 'FHIR', 'IG'
      end

      def self.source_root
        File.join(__dir__, 'templates')
      end

      def create_app
        @name = name
        @ig_uri = options['implementation_guide']
        @authors = options['author']

        ## Template Generation:
        # copies all files from ./templates/ folder
        # performs ERB substitution on all .tt files and removes .tt suffix
        # replaces all %foo% file names with foo() method call
        directory('.', root_name, { mode: :preserve, recursive: true })

        case @ig_uri
        when /^https?:\/\//
          @ig_uri = @ig_uri.gsub(/[^\/]*\.html\s*$/, 'package.tgz')
          @ig_uri = File.join(@ig_uri, 'package.tgz') unless @ig_uri.ends_with? 'package.tgz'

          response = Faraday.get(@ig_uri)
          if response.status == 200 # TODO validate file because an incorrect package.tgz will break inferno
            create_file(ig_file, response.body)
          else
            say "Failed to load #{@ig_uri}", :red
            say "Please add the implementation guide package.tgz file into #{ig_path}", :red
          end
        when ->(ig_uri) { ig_uri.nil? }
          say "If you want to test for an implementation guide, add its package.tgz file into #{ig_path}"
        else
          begin
            FileUtils.cp(@ig_uri, ig_file)
          rescue
            say "Failed to load #{@ig_uri}", :red
            say "Please add the implementation guide package.tgz file into #{ig_path}", :red
          end
        end

        say "Created #{root_name} test kit!", :green
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
        File.join(ig_path, 'package.tgz')
      end

      def ig_load_failed_error
        say "Failed to load #{@ig_uri}", :red
        say "Please add the implementation guide package.tgz file into #{ig_path}", :red        
      end

      # returns system username or 'TODO' in an array
      def fetch_user()
        [ ENV['USER'] || ENV['USERNAME'] || 'TODO' ]
      end
    end
  end
end
