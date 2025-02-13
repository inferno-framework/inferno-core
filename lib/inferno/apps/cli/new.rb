require 'thor'
require 'bundler'
require_relative '../../utils/named_thor_actions'
require_relative '../../utils/ig_downloader'
require_relative '../../version'

module Inferno
  module CLI
    class New < Thor::Group
      include Thor::Actions
      include Inferno::Utils::NamedThorActions
      include Inferno::Utils::IgDownloader

      desc <<~HELP
        Generate a new Inferno test kit for FHIR software testing

        Examples:

          `inferno new my_test_kit`
            => generates an Inferno test kit

          `inferno new test-us-core -i hl7.fhir.us.core@6.1.0`
            => generates Inferno test kit with US Core 6.1.0 implementation guide

          `inferno new TestMatching -i https://build.fhir.org/ig/HL7/fhir-identity-matching-ig/`
            => generates Inferno test kit with an implementation guide from its continuous web build

          `inferno new test-my-ig -a "My Name" -i file:///absolute/path/to/my/ig/package.tgz`
            => generates Inferno test kit with a local IG and specifies My Name as gem author

           `inferno new test_my_igs -a "My Name" -a "Another Name" -i file:///my/first/package.tgz -i hl7.fhir.us.core@6.1.0`
            => generates Inferno test kit with multiple IGs and multiple authors

        https://inferno-framework.github.io/index.html
      HELP

      def self.banner
        'inferno new TEST_KIT_NAME'
      end

      def self.source_root
        File.join(__dir__, 'templates')
      end

      argument :name,
               type: :string,
               required: true,
               desc: 'name for new Inferno project'
      class_option :author,
                   type: :string,
                   aliases: '-a',
                   default: [],
                   repeatable: true,
                   desc: "Author names for gemspec file; you may use '-a' multiple times"
      class_option :skip_bundle,
                   type: :boolean,
                   aliases: '-b',
                   default: false,
                   desc: 'Do not run bundle install or inferno migrate'
      class_option :implementation_guide,
                   type: :string,
                   aliases: '-i',
                   repeatable: true,
                   desc: 'Load an Implementation Guide by FHIR Registry name, URL, or absolute path'

      add_runtime_options!

      def create_test_kit
        directory('.', root_name, { mode: :preserve, recursive: true, verbose: !options['quiet'] })

        inside(root_name) do
          bundle_install
          inferno_migrate
          initialize_git_repo
          load_igs
        end

        say_unless_quiet "Created #{root_name} Inferno Test Kit!", :green

        return unless options['pretend']

        say_unless_quiet 'This was a dry run; re-run without `--pretend` to actually create project',
                         :yellow
      end

      private

      def authors
        (options['author'].presence || [default_author]).to_json.gsub('"', "'")
      end

      def default_author
        ENV['USER'] || ENV['USERNAME'] || 'PUT_YOUR_NAME_HERE'
      end

      def bundle_install
        return if options['skip_bundle']

        Bundler.with_unbundled_env do
          run 'bundle install', verbose: !options['quiet'], capture: options['quiet']
        end
      end

      def inferno_migrate
        return if options['skip_bundle']

        run 'bundle exec inferno migrate', verbose: !options['quiet'], capture: options['quiet']
      end

      def initialize_git_repo
        run 'git init -q && git add . && git commit -aqm "initial commit"'
      end

      def load_igs
        options['implementation_guide']&.each_with_index do |ig, idx|
          uri = options['implementation_guide'].length == 1 ? load_ig(ig, nil) : load_ig(ig, idx)
          say_unless_quiet "Downloaded IG from #{uri}"
        rescue OpenURI::HTTPError => e
          say_unless_quiet "Failed to install implementation guide #{ig}", :red
          say_unless_quiet e.message, :red
        rescue StandardError => e
          say_unless_quiet e.message, :red
        end
      end

      def say_unless_quiet(*)
        say(*) unless options['quiet']
      end
    end
  end
end
