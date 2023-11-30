require 'thor'
require_relative '../../utils/named_thor_actions'

module Inferno
  module CLI
    class New < Thor::Group
      include Thor::Actions
      include Inferno::Utils::NamedThorActions

      desc <<~HELP
        Generate a new Inferno test kit for FHIR software testing

        Examples:

          `inferno new test_fhir_app`
            => generates an Inferno app

          `inferno new test_us_core -i https://build.fhir.org/ig/HL7/US-Core/`
            => generates Inferno app and loads US Core implementation guide

          `inferno new test_my_ig -i /absolute/path/to/ig/package.tgz -a Name`
            => generates Inferno app, loads a local implementation guide, and specifies Name as author

        https://inferno-framework.github.io/index.html
      HELP

      def self.banner
        'inferno new TEST_KIT_NAME [-i IG_URL]'
      end

      def self.source_root
        File.join(__dir__, 'templates')
      end

      argument :name,
               type: :string,
               required: true,
               desc: 'name for new Inferno project'
      class_option :implementation_guide,
                   type: :string,
                   aliases: '-i',
                   default: nil,
                   banner: 'IG_URL',
                   desc: 'URL to an implementation guide or absolute path to a package.tgz'
      class_option :author,
                   type: :string,
                   aliases: '-a',
                   default: [],
                   repeatable: true,
                   desc: "Author names for gemspec file; you may use '-a' multiple times"

      add_runtime_options!

      def create_app
        directory('.', root_name, { mode: :preserve, recursive: true, verbose: !options['quiet'] })
        load_ig
        say_unless_quiet "Created #{root_name} Inferno test kit!", :green

        return unless options['pretend']

        say_unless_quiet 'This was a dry run; re-run without `--pretend` to actually create project',
                         :yellow
      end

      private

      def load_ig
        return unless normalized_ig_uri

        begin
          get(normalized_ig_uri, ig_file, verbose: !options['quiet'])
        rescue StandardError => e
          say_error e.message, :red
          say_error "Failed to load #{normalized_ig_uri}", :red
          say_error "Please add the implementation guide package.tgz file into #{ig_path}", :red
        else
          say_unless_quiet "Loaded implementation guide #{normalized_ig_uri}", :green
        end
      end

      def normalized_ig_uri
        uri = options['implementation_guide']
        return if uri.nil?

        uri = uri.gsub(%r{[^/]*\.html\s*$}, 'package.tgz')
        uri = File.join(uri, 'package.tgz') unless uri.ends_with? 'package.tgz'
        uri
      end

      def ig_path
        File.join('lib', library_name, 'igs')
      end

      def ig_file
        File.join(root_name, ig_path, 'package.tgz')
      end

      def authors
        options['author'].empty? ? options['author'].append(default_author) : options['author']
      end

      def default_author
        ENV['USER'] || ENV['USERNAME'] || 'TODO'
      end

      def say_unless_quiet(*args)
        say(*args) unless options['quiet']
      end
    end
  end
end
