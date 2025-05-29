module Inferno
  module CLI
    class RequirementsCoverageChecker
      attr_accessor :test_suite_id, :test_suite

      # Derivative constants
      TEST_KIT_CODE_FOLDER = TEST_KIT_ID
      DASHERIZED_TEST_KIT_ID = TEST_KIT_ID.gsub('_', '-')
      INPUT_HEADERS = [
        'Req Set',
        'ID',
        'URL',
        'Requirement',
        'Conformance',
        'Actor',
        'Sub-Requirement(s)',
        'Conditionality'
      ].freeze
      SHORT_ID_HEADER = 'Short ID(s)'
      FULL_ID_HEADER = 'Full ID(s)'
      INPUT_FILE_NAME = "#{DASHERIZED_TEST_KIT_ID}_requirements.csv".freeze
      INPUT_FILE = File.join('lib', TEST_KIT_CODE_FOLDER, 'requirements', INPUT_FILE_NAME).freeze
      OUTPUT_HEADERS = INPUT_HEADERS + TEST_SUITES.flat_map do |suite|
                                         ["#{suite.title} #{SHORT_ID_HEADER}", "#{suite.title} #{FULL_ID_HEADER}"]
                                       end

      def initialize(test_suite_id)
        self.test_suite_id = test_suite_id
        self.test_suite = Inferno::Repositories::TestSuites.new.find(test_suite_id)
      end

      def test_kit_name
        local_test_kit_gem.name
      end

      def base_requirements_folder
        @base_requirements_folder ||= Dir.glob(File.join(Dir.pwd, 'lib', '*', 'requirements')).first
      end

      def not_tested_file_name
        "#{test_kit_name}_out_of_scope_requirements.csv"
      end

      def not_tested_file_path
        File.join(base_requirements_folder, not_tested_file_name)
      end

      def output_folder
        @base_requirements_folder ||= File.join(base_requirements_folder, 'generated')
      end

      def output_file_name
        "#{test_suite_id}_requirements_coverage.csv"
      end

      def output_file_path
        @output_file_path ||= File.join(output_folder, output_file_name)
      end

      def suite_requirements
        @suite_requirements ||=
          Inferno::Repositories::Requirements.new.requirments_for_suite(test_suite_id)
      end

      def tested_requirements
        @tested_requirements ||=
          test_suite.all_requirements
      end

      def input_rows
        @input_rows ||=
          CSV.parse(File.open(INPUT_FILE, 'r:bom|utf-8'), headers: true).map do |row|
          row.to_h.slice(*INPUT_HEADERS)
        end
      end

      def not_tested_requirements_map
        @not_tested_requirements_map ||= load_not_tested_requirements
      end

      def load_not_tested_requirements
        return {} unless File.exist?(not_tested_file_path)

        not_tested_requirements = {}
        CSV.parse(File.open(not_tested_file_path, 'r:bom|utf-8'), headers: true).each do |row|
          row_hash = row.to_h
          not_tested_requirements["#{row_hash['Req Set']}@#{row_hash['ID']}"] = row_hash
        end

        not_tested_requirements
      end

      # Of the form:
      # {
      #     'req-id-1': [
      #       { short_id: 'short-id-1', full_id: 'long-id-1', suite_id: 'suite-id-1' },
      #       { short_id: 'short-id-2', full_id: 'long-id-2', suite_id: 'suite-id-2' }
      #     ],
      #     'req-id-2': [{ short_id: 'short-id-3', full_id: 'long-id-3', suite_id: 'suite-id-3' }],
      #     ...
      # }
      def inferno_requirements_map
        @inferno_requirements_map ||= TEST_SUITES.each_with_object({}) do |suite, requirements_map|
          serialize_requirements(suite, 'suite', suite.id, requirements_map)
          suite.groups.each do |group|
            map_group_requirements(group, suite.id, requirements_map)
          end
        end
      end

      def new_csv
        @new_csv ||=
          CSV.generate(+"\xEF\xBB\xBF") do |csv|
            csv << OUTPUT_HEADERS
            input_rows.each do |row| # NOTE: use row order from source file
              next if row['Conformance'] == 'DEPRECATED' # filter out deprecated rows

              TEST_SUITES.each do |suite|
                suite_actor = SUITE_ID_TO_ACTOR_MAP[suite.id]
                if row['Actor']&.include?(suite_actor)
                  add_suite_tests_for_row(row, suite)
                else
                  row["#{suite.title} #{SHORT_ID_HEADER}"] = 'NA'
                  row["#{suite.title} #{FULL_ID_HEADER}"] = 'NA'
                end
              end
              csv << row.values
            end
          end
      end

      def add_suite_tests_for_row(row, suite)
        set_and_req_id = "#{row['Req Set']}@#{row['ID']}"
        items = get_items_for_requirement(set_and_req_id, suite)
        short_ids = items[0]
        full_ids = items[1]
        if short_ids.blank? && not_tested_requirements_map.key?(set_and_req_id)
          row["#{suite.title} #{SHORT_ID_HEADER}"] = 'Not Tested'
          row["#{suite.title} #{FULL_ID_HEADER}"] = 'Not Tested'
        else
          row["#{suite.title} #{SHORT_ID_HEADER}"] = short_ids&.join(', ')
          row["#{suite.title} #{FULL_ID_HEADER}"] = full_ids&.join(', ')
        end
      end

      def get_items_for_requirement(set_and_req_id, suite)
        suite_requirement_items = inferno_requirements_map[set_and_req_id]&.filter do |item|
          item[:suite_id] == suite.id
        end
        [
          suite_requirement_items&.map { |item| item[:short_id] },
          suite_requirement_items&.map { |item| item[:full_id] }
        ]
      end

      def input_requirement_ids
        @input_requirement_ids ||= input_rows.map { |row| "#{row['Req Set']}@#{row['ID']}" }
      end

      # The requirements present in Inferno that aren't in the input spreadsheet
      def unmatched_requirements_map
        @unmatched_requirements_map ||= inferno_requirements_map.except(*input_requirement_ids)
      end

      def old_csv
        @old_csv ||= File.read(output_file_path)
      end

      def run
        unless File.exist?(INPUT_FILE)
          puts "Could not find input file: #{INPUT_FILE}. Aborting requirements coverage generation..."
          exit(1)
        end

        if unmatched_requirements_map.any?
          puts "WARNING: The following requirements indicated in the test kit are not present in #{INPUT_FILE_NAME}"
          output_requirements_map_table(unmatched_requirements_map)
        end

        if File.exist?(output_file_path)
          if old_csv == new_csv
            puts "'#{output_file_name}' file is up to date."
            return
          else
            puts 'Requirements coverage has changed.'
          end
        else
          puts "No existing #{output_file_name}."
        end

        puts "Writing to file #{output_file_path}..."
        FileUtils.mkdir_p(output_folder)
        File.write(output_file_path, new_csv)
        puts 'Done.'
      end

      def run_check
        unless File.exist?(INPUT_FILE)
          puts "Could not find input file: #{INPUT_FILE}. Aborting requirements coverage check..."
          exit(1)
        end

        if unmatched_requirements_map.any?
          puts "The following requirements indicated in the test kit are not present in #{INPUT_FILE_NAME}"
          output_requirements_map_table(unmatched_requirements_map)
        end

        if File.exist?(output_file_path)
          if old_csv == new_csv
            puts "'#{output_file_name}' file is up to date."
            return unless unmatched_requirements_map.any?
          else
            puts <<~MESSAGE
              #{output_file_name} file is out of date.
              To regenerate the file, run:

                  bundle exec rake requirements:generate_coverage

            MESSAGE
          end
        else
          puts <<~MESSAGE
            No existing #{output_file_name} file.
            To generate the file, run:

                  bundle exec rake requirements:generate_coverage

          MESSAGE
        end

        puts 'Check failed.'
        exit(1)
      end

      def map_group_requirements(group, suite_id, requirements_map)
        serialize_requirements(group, group.short_id, suite_id, requirements_map)
        group.tests&.each { |test| serialize_requirements(test, test.short_id, suite_id, requirements_map) }
        group.groups&.each { |subgroup| map_group_requirements(subgroup, suite_id, requirements_map) }
      end

      def serialize_requirements(runnable, short_id, suite_id, requirements_map)
        runnable.verifies_requirements&.each do |requirement_id|
          requirement_id_string = requirement_id.to_s

          requirements_map[requirement_id_string] ||= []
          requirements_map[requirement_id_string] << { short_id:, full_id: runnable.id, suite_id: }
        end
      end

      # Output the requirements in the map like so:
      #
      # requirement_id | short_id   | full_id
      # ---------------+------------+----------
      # req-id-1       | short-id-1 | full-id-1
      # req-id-2       | short-id-2 | full-id-2
      #
      def output_requirements_map_table(requirements_map)
        headers = %w[requirement_id short_id full_id]
        col_widths = headers.map(&:length)
        col_widths[0] = [col_widths[0], requirements_map.keys.map(&:length).max].max
        col_widths[1] = ([col_widths[1]] + requirements_map.values.flatten.map { |item| item[:short_id].length }).max
        col_widths[2] = ([col_widths[2]] + requirements_map.values.flatten.map { |item| item[:full_id].length }).max
        col_widths.map { |width| width + 3 }

        puts [
          headers[0].ljust(col_widths[0]),
          headers[1].ljust(col_widths[1]),
          headers[2].ljust(col_widths[2])
        ].join(' | ')
        puts col_widths.map { |width| '-' * width }.join('-+-')
        output_requirements_map_table_contents(requirements_map, col_widths)
        puts
      end

      def output_requirements_map_table_contents(requirements_map, col_widths)
        requirements_map.each do |requirement_id, runnables|
          runnables.each do |runnable|
            puts [
              requirement_id.ljust(col_widths[0]),
              runnable[:short_id].ljust(col_widths[1]),
              runnable[:full_id].ljust(col_widths[2])
            ].join(' | ')
          end
        end
      end
    end
  end
end
