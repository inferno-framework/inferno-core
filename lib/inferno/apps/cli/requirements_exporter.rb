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
          'Actors*',
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
          'Actors',
          'Sub-Requirement(s)',
          'Conditionality',
          'Not Tested Reason',
          'Not Tested Details'
        ].freeze

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
        @input_requirement_sets ||=
          begin
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
      end

      def new_requirements_csv # rubocop:disable Metrics/CyclomaticComplexity
        @new_requirements_csv ||=
          CSV.generate(+"\xEF\xBB\xBF") do |csv| # start with an unnecessary BOM to make viewing in excel easier
            csv << REQUIREMENTS_OUTPUT_HEADERS

            input_requirement_sets.each do |requirement_set_id, input_rows|
              input_rows.each do |row| # NOTE: use row order from source file
                csv << REQUIREMENTS_OUTPUT_HEADERS.map do |header|
                  (
                    case header
                    when 'Req Set'
                      requirement_set_id
                    when 'Not Tested Reason'
                      if spreadsheet_value_falsy?(row['Verifiable?'])
                        'Not Verifiable'
                      elsif spreadsheet_value_falsy?(row['Planning To Test?'])
                        'Not Tested'
                      end
                    when 'Not Tested Details'
                      if spreadsheet_value_falsy?(row['Verifiable?'])
                        row['Verifiability Details']
                      elsif spreadsheet_value_falsy?(row['Planning To Test?'])
                        row['Planning To Test Details']
                      end
                    else
                      row[header] || row["#{header}*"]
                    end
                  )&.strip
                end
              end
            end
          end
      end

      def old_requirements_csv
        @old_requirements_csv ||= File.read(requirements_output_file_path)
      end

      def missing_sub_requirements
        @missing_sub_requirements =
          {}.tap do |missing_requirements|
            repo = Inferno::Repositories::Requirements.new

            input_requirement_sets
              .each do |requirement_set, requirements|
                requirements.each do |requirement_hash|
                  missing_sub_requirements =
                    Inferno::Entities::Requirement.expand_requirement_ids(requirement_hash['Sub-Requirement(s)'])
                      .reject { |requirement_id| repo.exists? requirement_id }

                  missing_sub_requirements += missing_actor_sub_requirements(requirement_hash['Sub-Requirement(s)'])

                  next if missing_sub_requirements.blank?

                  id = "#{requirement_set}@#{requirement_hash['ID*']}"

                  missing_requirements[id] = missing_sub_requirements
                end
              end
          end
      end

      def missing_actor_sub_requirements(sub_requirement_string)
        return [] if sub_requirement_string.blank?

        return [] unless sub_requirement_string.include? '#'

        sub_requirement_string
          .split(',')
          .map(&:strip)
          .select { |requirement_string| requirement_string.include? '#' }
          .select do |requirement_string|
            Inferno::Entities::Requirement.expand_requirement_ids(requirement_string).blank?
          end
      end

      def check_sub_requirements
        return if missing_sub_requirements.blank?

        missing_sub_requirements.each do |id, sub_requirement_ids|
          puts "#{id} is missing the following sub-requirements:\n  #{sub_requirement_ids.join(', ')}"
        end
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

        check_sub_requirements

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

        unless requirements_ok
          puts <<~MESSAGE
            Check Failed. To resolve, run:

                  bundle exec inferno requirements export_csv

          MESSAGE
          exit(1)
        end

        check_sub_requirements

        return if missing_sub_requirements.blank?

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
