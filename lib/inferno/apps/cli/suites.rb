module Inferno
  module CLI
    class Suites
      def run
        ENV['NO_DB'] = 'true'

        require_relative '../../../inferno'

        Inferno::Application.start(:suites)

        suites = Inferno::Repositories::TestSuites.new.all
        suite_hash = suites.each_with_object({}) { |suite, hash| hash[suite.id] = suite.title }

        id_column_length = suite_hash.keys.map(&:length).max + 1
        title_column_length = suite_hash.values.map(&:length).max

        puts "#{'ID'.ljust(id_column_length)}| Title"
        puts "#{'-' * id_column_length}+-#{'-' * title_column_length}"
        suite_hash.each do |id, title|
          puts "#{id.ljust(id_column_length)}| #{title}"
        end
      end
    end
  end
end
