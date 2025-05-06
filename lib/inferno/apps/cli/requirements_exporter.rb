module Inferno
  module CLI
    class RequirementsExporter
      INPUT_HEADERS =
        [
          'ID*',
          'URL*',
          'Requirement*',
          'Conformance*',
          'Actor*',
          'Sub-Requirement(s)',
          'Conditionality',
          'Verifiable?',
          'Verifiability Details',
          'Planning To Test?',
          'Planning To Test Details'
        ].freeze
      REQUIREMENTS_OUTPUT_HEADERS =
        [
          'Req Set',
          'ID',
          'URL',
          'Requirement',
          'Conformance',
          'Actor',
          'Sub-Requirement(s)',
          'Conditionality'
        ].freeze
      PLANNED_NOT_TESTED_OUTPUT_HEADERS = ['Req Set', 'ID', 'Reason', 'Details'].freeze

      def local_test_kit_gem
        @local_test_kit_gem ||= Bundler.definition.specs.find { |spec| spec.full_gem_path == Dir.pwd }
      end

      def test_kit_name
        local_test_kit_gem.name
      end

      def base_requirements_folder
        @base_requirements_folder ||= File.join('lib', test_kit_name, 'requirements')
      end

      def requirements_output_file_name
        "#{test_kit_name}_requirements.csv"
      end

      def requirements_output_file_path
        File.join(base_requirements_folder, requirements_output_file_name).freeze
      end

      def planned_not_tested_output_file_name
        "#{test_kit_name}_out_of_scope_requirements.csv"
      end

      def planned_not_tested_output_file_path
        File.join(base_requirements_folder, planned_not_tested_output_file_name).freeze
      end

      def available_input_worksheets
        @available_input_worksheets ||= Dir.glob(File.join(base_requirements_folder, '*.xlsx')).reject { |f| f.include?('~$') }
      end

      # Of the form:
      # {
      #   req_set_id_1: [row1, row2, row 3, ...],
      #   req_set_id_2: [row1, row2, row 3, ...]
      # }
      def input_requirement_sets
        @input_requirement_sets ||= INPUT_SETS.each_with_object({}) do |req_set_id, hash|
          req_set_file = available_input_worksheets.find { |worksheet_file| worksheet_file.include?(req_set_id) }

          hash[req_set_id] =
            unless req_set_file.nil?
              CSV.parse(Roo::Spreadsheet.open(req_set_file).sheet('Requirements').to_csv,
                        headers: true).map do |row|
                row.to_h.slice(*INPUT_HEADERS)
              end
            end
        end
      end

      def new_requirements_csv
        @new_requirements_csv ||=
          CSV.generate(+"\xEF\xBB\xBF") do |csv| # start with an unnecessary BOM to make viewing in excel easier
            csv << REQUIREMENTS_OUTPUT_HEADERS

            input_requirement_sets.each do |req_set_id, input_rows|
              input_rows.each do |input_row| # NOTE: use row order from source file
                csv << REQUIREMENTS_OUTPUT_HEADERS.map do |header|
                  header == 'Req Set' ? req_set_id : input_row[header] || input_row["#{header}*"]
                end
              end
            end
          end
      end

      def old_requirements_csv
        @old_requirements_csv ||= File.read(requirements_output_file_name)
      end

      def new_planned_not_tested_csv
        @new_planned_not_tested_csv ||=
          CSV.generate(+"\xEF\xBB\xBF") do |csv| # start with an unnecessary BOM to make viewing in excel easier
            csv << PLANNED_NOT_TESTED_OUTPUT_HEADERS

            input_requirement_sets.each do |req_set_id, input_rows|
              input_rows.each do |row|
                if spreadsheet_value_falsy?(row['Verifiable?'])
                  csv << [req_set_id, row['ID*'], 'Not Verifiable', row['Verifiability Details']]
                elsif spreadsheet_value_falsy?(row['Planning To Test?'])
                  csv << [req_set_id, row['ID*'], 'Not Tested', row['Planning To Test Details']]
                end
              end
            end
          end
      end

      def old_planned_not_tested_csv
        @old_planned_not_tested_csv ||= File.read(planned_not_tested_output_file_path)
      end

      def run
        check_presence_of_input_files

        update_requirements =
          if File.exist?(requirements_output_file_name)
            if old_requirements_csv == new_requirements_csv
              puts "'#{requirements_output_file_name}' file is up to date."
              false
            else
              puts 'Requirements set has changed.'
              true
            end
          else
            puts "No existing #{requirements_output_file_name}."
            true
          end

        if update_requirements
          puts "Writing to file #{requirements_output_file_name}..."
          File.write(requirements_output_file_name, new_requirements_csv, encoding: Encoding::UTF_8)
        end

        udpate_planned_not_tested =
          if File.exist?(planned_not_tested_output_file_path)
            if old_planned_not_tested_csv == new_planned_not_tested_csv
              puts "'#{planned_not_tested_output_file_name}' file is up to date."
              false
            else
              puts 'Planned Not Tested Requirements set has changed.'
              true
            end
          else
            puts "No existing #{planned_not_tested_output_file_name}."
            true
          end

        if udpate_planned_not_tested
          puts "Writing to file #{planned_not_tested_output_file_path}..."
          File.write(planned_not_tested_output_file_path, new_planned_not_tested_csv, encoding: Encoding::UTF_8)
        end

        puts 'Done.'
      end

      def run_check
        check_presence_of_input_files

        requirements_ok =
          if File.exist?(requirements_output_file_name)
            if old_requirements_csv == new_requirements_csv
              puts "'#{requirements_output_file_name}' file is up to date."
              true
            else
              puts "#{requirements_output_file_name} file is out of date."
              false
            end
          else
            puts "No existing #{requirements_output_file_name} file."
            false
          end

        planned_not_tested_requirements_ok =
          if File.exist?(planned_not_tested_output_file_path)
            if old_planned_not_tested_csv == new_planned_not_tested_csv
              puts "'#{planned_not_tested_output_file_name}' file is up to date."
              true
            else
              puts "#{planned_not_tested_output_file_name} file is out of date."
              false
            end
          else
            puts "No existing #{planned_not_tested_output_file_name} file."
            false
          end

        return if planned_not_tested_requirements_ok && requirements_ok

        puts <<~MESSAGE
          Check Failed. To resolve, run:

                bundle exec rake "requirements:collect[<base_requirements_folder>]"

        MESSAGE
        exit(1)
      end

      def check_presence_of_input_files
        input_requirement_sets.each do |req_set_id, rows|
          next unless rows.nil?

          puts %(
            Could not find input file for set #{req_set_id} in directory #{base_requirements_folder}. Aborting requirements
            collection..."
          )
          exit(1)
        end
      end

      def spreadsheet_value_falsy?(str)
        str&.downcase == 'no' || str&.downcase == 'false'
      end
    end
  end
end
