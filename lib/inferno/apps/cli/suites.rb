require 'tty-markdown'

module Inferno
  module CLI
    class Suites
      def run
        ENV['NO_DB'] = 'true'

        Inferno::Application.start(:suites)

        suites = Inferno::Repositories::TestSuites.new.all
        suite_hash = suites.each_with_object({}) { |suite, hash| hash[suite.id] = suite.title }

        id_column_length = suite_hash.keys.map(&:length).max + 2
        title_column_length = suite_hash.values.map(&:length).max + 1

        output = ''
        output += "| #{'Title'.ljust(title_column_length)}| #{'ID'.ljust(id_column_length)}|\n"
        output += "|-#{'-' * title_column_length}|-#{'-' * id_column_length}|\n"

        suite_hash.each do |id, title|
          output += "| #{title.ljust(title_column_length)}| #{id.ljust(id_column_length)}|\n"
        end

        puts TTY::Markdown.parse(output)
      end
    end
  end
end
