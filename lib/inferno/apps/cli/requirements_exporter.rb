require 'csv'
require 'roo'

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
        @base_requirements_folder ||= Dir.glob(File.join(Dir.pwd, 'lib', '*', 'requirements')).first
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
        @available_input_worksheets ||=
          Dir.glob(File.join(base_requirements_folder, '*.xlsx'))
            .reject { |f| f.include?('~$') }
      end

      def requirement_set_id(worksheet)
        sheet = worksheet.sheet('Metadata')
        id_row = sheet.column(1).find_index('Id') + 1
        sheet.row(id_row)[1]
      end

      # Of the form:
      # {
      #   requirement_set_id_1: [row1, row2, row 3, ...],
      #   requirement_set_id_2: [row1, row2, row 3, ...]
      # }
      def input_requirement_sets
        requirement_set_hash = Hash.new { |hash, key| hash[key] = [] }
        available_input_worksheets.each_with_object(requirement_set_hash) do |worksheet_file, requirement_sets|
          worksheet = Roo::Spreadsheet.open(worksheet_file)
          set_identifier = requirement_set_id(worksheet)

          CSV.parse(
            worksheet.sheet('Requirements').to_csv,
            headers: true
          ).each do |row|
            row_hash = row.to_h.slice(*INPUT_HEADERS)
            row_hash['Sub-Requirement(s)']&.delete_prefix!('mailto:')

            requirement_sets[set_identifier] << row_hash
          end
        end
      end

      def new_requirements_csv # rubocop:disable Metrics/CyclomaticComplexity
        @new_requirements_csv ||=
          CSV.generate(+"\xEF\xBB\xBF") do |csv| # start with an unnecessary BOM to make viewing in excel easier
            csv << REQUIREMENTS_OUTPUT_HEADERS

            input_requirement_sets.each do |requirement_set_id, input_rows|
              input_rows.each do |input_row| # NOTE: use row order from source file
                csv << REQUIREMENTS_OUTPUT_HEADERS.map do |header|
                  (header == 'Req Set' ? requirement_set_id : input_row[header] || input_row["#{header}*"])&.strip
                end
              end
            end
          end
      end

      def old_requirements_csv
        @old_requirements_csv ||= File.read(requirements_output_file_path)
      end

      def new_planned_not_tested_csv
        @new_planned_not_tested_csv ||=
          CSV.generate(+"\xEF\xBB\xBF") do |csv| # start with an unnecessary BOM to make viewing in excel easier
            csv << PLANNED_NOT_TESTED_OUTPUT_HEADERS

            input_requirement_sets.each do |requirement_set_id, input_rows|
              input_rows.each do |row|
                if spreadsheet_value_falsy?(row['Verifiable?'])
                  csv << [requirement_set_id, row['ID*'], 'Not Verifiable', row['Verifiability Details']]
                elsif spreadsheet_value_falsy?(row['Planning To Test?'])
                  csv << [requirement_set_id, row['ID*'], 'Not Tested', row['Planning To Test Details']]
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
          if File.exist?(requirements_output_file_path)
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
          File.write(requirements_output_file_path, new_requirements_csv, encoding: Encoding::UTF_8)
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
          if File.exist?(requirements_output_file_path)
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

                bundle exec inferno requirements export_csv

        MESSAGE
        exit(1)
      end

      def check_presence_of_input_files
        return if available_input_worksheets.present?

        puts 'Could not find any input files in directory ' \
             "#{base_requirements_folder}. Aborting requirements collection."
        exit(1)
      end

      def spreadsheet_value_falsy?(string)
        ['no', 'false'].include? string&.downcase
      end
    end
  end
end
