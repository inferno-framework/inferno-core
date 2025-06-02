require_relative 'requirements_exporter'

module Inferno
  module CLI
    class RequirementsCoverageChecker
      attr_accessor :test_suite_id, :test_suite

      def initialize(test_suite_id)
        self.test_suite_id = test_suite_id
        self.test_suite = Inferno::Repositories::TestSuites.new.find(test_suite_id)
      end

      def short_id_header
        "#{test_suite.title} Short ID(s)"
      end

      def full_id_header
        "#{test_suite.title} Full ID(s)"
      end

      def output_headers
        [*RequirementsExporter::REQUIREMENTS_OUTPUT_HEADERS, short_id_header, full_id_header]
      end

      def test_kit_name
        local_test_kit_gem.name
      end

      def base_requirements_folder
        RequirementsExporter.new.base_requirements_folder
      end

      def output_folder
        @output_folder ||= File.join(base_requirements_folder, 'generated')
      end

      def output_file_name
        "#{test_suite_id}_requirements_coverage.csv"
      end

      def output_file_path
        @output_file_path ||= File.join(output_folder, output_file_name)
      end

      def suite_requirements
        @suite_requirements ||=
          Inferno::Repositories::Requirements.new.requirements_for_suite(test_suite_id)
      end

      def tested_requirement_ids
        @tested_requirement_ids ||= test_suite.all_requirements
      end

      def suite_runnables
        @suite_runnables ||= test_suite.all_descendants
      end

      def untested_requirements
        @untested_requirements ||= []
      end

      def new_csv
        @new_csv ||=
          CSV.generate(+"\xEF\xBB\xBF") do |csv|
            csv << output_headers

            suite_requirements.each do |requirement|
              if requirement.not_tested_reason.present?
                long_ids = 'NA'
                short_ids = 'NA'
              else
                runnables_for_requirement =
                  suite_runnables.select { |runnable| runnable.verifies_requirements.include? requirement.id }
                long_ids = runnables_for_requirement&.map(&:id)&.join(', ')
                short_ids = runnables_for_requirement&.map(&:short_id)&.join(', ')
              end

              untested_requirements << runnables_for_requirement if runnables_for_requirement.blank?

              row = [
                requirement.requirement_set,
                requirement.id.delete_prefix("#{requirement.requirement_set}@"),
                requirement.url,
                requirement.requirement,
                requirement.conformance,
                requirement.actor,
                requirement.sub_requirements.presence&.join(', '),
                requirement.conditionality,
                requirement.not_tested_reason,
                requirement.not_tested_details,
                short_ids,
                long_ids
              ]

              csv << row
            end
          end
      end

      def input_requirement_ids
        @input_requirement_ids ||= input_rows.map { |row| "#{row['Req Set']}@#{row['ID']}" }
      end

      # The requirements present in Inferno that aren't in the input spreadsheet
      def unmatched_requirement_ids
        @unmatched_requirement_ids ||=
          tested_requirement_ids - suite_requirements.map(&:id)
      end

      def unmatched_requirement_rows
        unmatched_requirement_ids.flat_map do |requirement_id|
          runnables_for_requirement =
            suite_runnables.select { |runnable| runnable.verifies_requirements.include? requirement_id }

          runnables_for_requirement.map do |runnable|
            [requirement_id, runnable.short_id, runnable.id]
          end
        end
      end

      def old_csv
        @old_csv ||= File.read(output_file_path)
      end

      def run
        unless test_suite.present?
          puts "Could not find test suite: #{test_suite_id}. Aborting requirements coverage generation..."
          exit(1)
        end

        if unmatched_requirement_ids.present?
          puts "WARNING: The following requirements indicated in the test suite are not present in the suite's requirement sets:"
          output_requirements_map_table(unmatched_requirement_rows)
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
        unless test_suite.present?
          puts "Could not find test suite: #{test_suite_id}. Aborting requirements coverage generation..."
          exit(1)
        end

        if unmatched_requirement_ids.any?
          puts "WARNING: The following requirements indicated in the test suite are not present in the suite's requirement sets:"
          output_requirements_map_table(unmatched_requirements_map)
        end

        if File.exist?(output_file_path)
          if old_csv == new_csv
            puts "'#{output_file_name}' file is up to date."
            return unless unmatched_requirements_id.present?
          else
            puts <<~MESSAGE
              #{output_file_name} file is out of date.
              To regenerate the file, run:

                  bundle exec inferno requirements coverage #{test_suite_id}

            MESSAGE
          end
        else
          puts <<~MESSAGE
            No existing #{output_file_name} file.
            To generate the file, run:

                  bundle exec inferno requirements coverage #{test_suite_id}

          MESSAGE
        end

        puts 'Check failed.'
        exit(1)
      end

      # Output the requirements in the map like so:
      #
      # requirement_id | short_id   | full_id
      # ---------------+------------+----------
      # req-id-1       | short-id-1 | full-id-1
      # req-id-2       | short-id-2 | full-id-2
      #
      def output_requirements_map_table(requirements_rows)
        headers = %w[requirement_id short_id full_id]
        col_widths = headers.map(&:length)
        col_widths[0] = [col_widths[0], *requirements_rows.map { |row| row[0].length }].max
        col_widths[1] = [col_widths[1], *requirements_rows.map { |row| row[1].length }].max
        col_widths[2] = [col_widths[2], *requirements_rows.map { |row| row[2].length }].max
        col_widths.map! { |width| width + 3 }

        puts [
          headers[0].ljust(col_widths[0]),
          headers[1].ljust(col_widths[1]),
          headers[2].ljust(col_widths[2])
        ].join(' | ')
        puts col_widths.map { |width| '-' * width }.join('-+-')
        output_requirements_map_table_contents(requirements_rows, col_widths)
      end

      def output_requirements_map_table_contents(requirements_rows, col_widths)
        requirements_rows.each do |requirements_row|
          puts [
            requirements_row[0].ljust(col_widths[0]),
            requirements_row[1].ljust(col_widths[1]),
            requirements_row[2].ljust(col_widths[2])
          ].join(' | ')
        end
      end
    end
  end
end
