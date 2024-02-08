require 'thor'
require 'bundler'
require_relative '../../utils/named_thor_actions'
require_relative '../../version'

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

          `inferno new test_my_ig -a MyName`
            => generates Inferno app and specifies MyName as gemspec author

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
                   desc: 'Do not run bundle install'
      class_option :implementation_guide,
                   type: :string,
                   aliases: '-i',
                   repeatable: true,
                   desc: 'Load an Implementation Guide by FHIR Registry name, URL, or absolute path'

      add_runtime_options!

      def create_app
        directory('.', root_name, { mode: :preserve, recursive: true, verbose: !options['quiet'] })

        inside(root_name) do
          bundle_install
          inferno_migrate
          load_igs
        end

        say_unless_quiet "Created #{root_name} Inferno test kit!", :green

        return unless options['pretend']

        say_unless_quiet 'This was a dry run; re-run without `--pretend` to actually create project',
                         :yellow
      end

      private

      def ig_path
        File.join('lib', library_name, 'igs')
      end

      def ig_file(suffix = nil)
        File.join(ig_path, suffix ? "package_#{suffix}.tgz" : 'package.tgz')
      end

      def authors
        options['author'].presence || [default_author]
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

      FHIR_PACKAGE_NAME = /^[a-z][a-zA-Z0-9-]*\.([a-z][a-zA-Z0-9-]*\.?)*/
      HTTP_URI = %r(^https?:(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?)
      FILE_URI = %r(^file://(.+))

      def load_igs
        options['implementation_guide']&.each_with_index do |ig, idx|
          case ig
          when FHIR_PACKAGE_NAME
            if ig.rindex('@')
              ig = ig.split('@').join('/')
              get(File.join('https://packages.fhir.org/packages', ig), ig_file(idx))
            else
              say_unless_quiet 'No IG version specified; i.e: hl7.fhir.us.core@7.0.0-ballot', :red
            end
          when HTTP_URI
            unless ig.end_with? 'package.tgz'
              ig += 'package.tgz' if ig.end_with? '/'
              ig.gsub!(%r(/.+\.html), '/package.tgz') if ig.end_with? %r(/.+\.html)
            end
            get(ig, ig_file(idx))
          when FILE_URI
            get(ig, ig_file(idx))
          else
            say_unless_quiet "Could not find implementation guide: #{ig}", :red
            say_unless_quiet "Put its package.tgz file directly in #{ig_path}/", :red
          end
        end
      end

      def say_unless_quiet(*args)
        say(*args) unless options['quiet']
      end
    end
  end
end
