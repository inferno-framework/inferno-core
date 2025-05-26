require 'tty-markdown'

require_relative 'suite_input_template'

module Inferno
  module CLI
    class Suite < Thor
      desc 'input_template SUITE_ID', 'Create a template for preset inputs'
      long_desc <<~LONGDESC
        Generates a template for creating an input preset for a Test Suite.

        With -f option, the preset template is written to the specified
        filename.
      LONGDESC
      option :filename, banner: '<filename>', aliases: [:f]
      def input_template(suite_id)
        ENV['NO_DB'] = 'true'
        SuiteInputTemplate.new.run(suite_id, options)
      end

      desc 'describe SUITE_ID', 'Show information about a suite'
      long_desc <<~LONGDESC
        Display a suite's description and available options.
      LONGDESC
      def describe(suite_id)
        ENV['NO_DB'] = 'true'
        Inferno::Application.start(:suites)

        suite = Inferno::Repositories::TestSuites.new.find(suite_id)

        if suite.blank?
          message = "No suite found with id `#{suite_id}`. Run `inferno suites` to see a list of available suites"

          puts TTY::Markdown.parse(message)
          return
        end

        description = ''
        description += "# #{suite.title}\n"
        description += "#{suite.description}\n" if suite.description

        if suite.suite_options.present?
          description += "***\n\n"
          description += "# Suite Options\n\n"
          suite.suite_options.each do |option|
            description += "* `#{option.id}`: #{option.title}\n"
            option.list_options.each do |list_option|
              description += "  * `#{list_option[:value]}`: #{list_option[:label]}\n"
            end
          end
        end

        puts TTY::Markdown.parse(description)
      end

      desc 'lock_short_ids SUITE_ID', 'Persist the current short_id map for a suite'
      long_desc <<~LONGDESC
        Loads the given suite and writes its current short_id map to its corresponding YAML file.
      LONGDESC
      def lock_short_ids(suite_id)
        ENV['NO_DB'] = 'true'
        Inferno::Application.start(:suites)

        suite = Inferno::Repositories::TestSuites.new.find(suite_id)

        if suite.blank?
          message = "No suite found with id `#{suite_id}`. Run `inferno suites` to see a list of available suites"

          puts TTY::Markdown.parse(message)
          return
        end

        File.write(suite.short_id_file_path, suite.current_short_id_map.to_yaml)
        puts "Short ID map saved to #{suite.short_id_file_path}"
      end
    end
  end
end
