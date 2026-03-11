require_relative 'session_results'

module Inferno
  module CLI
    module Session
      class SessionCompare < SessionResults
        def run
          display_compared_results
          if options[:results_directory].present? && options[:save_results]
            save_actual_results_to_file
            save_comparison_csv_to_file
          end

          if results_match?
            exit(0)
          else
            exit(3)
          end
        end

        def results_timestamp
          @results_timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
        end

        def save_actual_results_to_file
          actual_results_file_name = "actual_results_#{results_timestamp}.json"
          File.write(File.join(options[:results_directory], actual_results_file_name), session_results.to_json)
        end

        def save_comparison_csv_to_file
          compared_csv_file_name = "compared_results_#{results_timestamp}.csv"
          File.write(File.join(options[:results_directory], compared_csv_file_name),
                     compared_results_as_csv)
        end

        def display_compared_results
          puts "Comparing results: #{results_match? ? 'Matched!' : 'Failed!'}"
          puts ''
          puts 'Test Details:'
          compared_results.map do |comparison|
            puts "  - #{comparison.display_string}"
          end
        end

        def compared_results_as_csv
          CSV.generate do |csv|
            csv << ['id', 'expected', 'actual', 'different?']
            compared_results.each do |result|
              next unless options[:csv_output_all_tests] && result.different_result?

              csv << result.comparison_csv_row
            end
          end
        end

        def results_match?
          compared_results.all?(&:same_result?)
        end

        def expected_results
          @expected_results ||= if options[:expected_results_session].present?
                                  results_for_session(options[:expected_results_session])
                                elsif options[:expected_results_file].present?
                                  JSON.parse(File.read(options[:expected_results_file]))
                                elsif options[:results_directory].present? &&
                                      File.exist?(File.join(options[:results_directory], 'expected_results.json'))
                                  JSON.parse(File.read(File.join(options[:results_directory], 'expected_results.json')))
                                else
                                  error = { errors: 'No expected results provided.' }
                                  puts error.to_json
                                  exit(3)
                                end
        end

        def compared_results
          @compared_results = match_result_ids(expected_results, session_results)
        end

        def match_result_ids(expected, actual)
          expected_hash = results_hash_by_id(expected)
          actual_hash = results_hash_by_id(actual)

          compared_results = expected_hash.map do |id, result|
            ComparedTestResult.new(id, result, actual_hash[id], options)
          end
          actual_hash.keys.reject { |id| expected_hash.key?(id) }.each do |id|
            compared_results << ComparedTestResult.new(id, nil, actual_hash[id], options)
          end

          compared_results
        end

        def results_hash_by_id(results)
          results.each_with_object({}) do |result, hash|
            key = result['test_id'] || result['test_group_id'] || result['test_suite_id']
            hash[key] = result
          end
        end

        class ComparedTestResult
          attr_reader :id, :expected_result, :actual_result, :options

          def initialize(id, expected_result, actual_result, options)
            @id = id
            @expected_result = expected_result
            @actual_result = actual_result
            @options = options
            @same = calculate_result
          end

          def calculate_result
            return false unless type == 'Compared'
            return false unless expected_result['result'] == actual_result['result']

            if options[:compare_result_message] && expected_result['result_message'] != actual_result['result_message']
              return false
            end
            return false if options[:compare_messages] && !same_messages?

            true
          end

          def same_messages?
            return false unless expected_result['messages']&.size == actual_result['messages']&.size
            return true unless expected_result['messages'].present?

            (0...expected_result['messages'].size).each do |message_index|
              expected_message = expected_result['messages'][message_index]
              actual_message = actual_result['messages'][message_index]
              next if same_message?(expected_message, actual_message)

              return false
            end

            true
          end

          def same_message?(expected_message, actual_message)
            expected_message['type'] == actual_message['type'] &&
              expected_message['message'] == actual_message['message']
          end

          def same_result?
            @same
          end

          def different_result?
            !same_result?
          end

          def display_string
            "#{id}: #{comparison_string}"
          end

          def comparison_string
            if type == 'Compared'
              if same_result?
                "Got '#{expected_result['result']}' as expected"
              else
                "Expected '#{expected_result['result']}', got '#{actual_result['result']}'"
              end
            elsif type == 'Additional'
              "Unexpected '#{actual_result['result']}'"
            else
              "Missing '#{expected_result['result']}'"
            end
          end

          def comparison_csv_header_row
            header_row = ['id', 'different?', 'expected result', 'actual result']
            if options[:compare_result_message]
              header_row << 'expected result_message'
              header_row << 'actual result_message'
            end
            if options[:compare_messages]
              header_row << 'expected messages'
              header_row << 'actual messages'
            end

            header_row
          end

          def comparison_csv_row
            row = [id, different_result?, expected_result&.dig('result'), actual_result&.dig('result')]
            if options[:compare_result_message]
              row << expected_result&.dig('result_message')
              row << actual_result&.dig('result_message')
            end
            if options[:compare_messages]
              row << format_messages_for_csv(expected_result)
              row << format_messages_for_csv(actual_result)
            end
            row
          end

          def type
            if expected_result.nil?
              'Additional'
            elsif actual_result.nil?
              'Missing'
            else
              'Compared'
            end
          end

          def format_messages_for_csv(results)
            return '' unless results['messages'].present?

            combined_messages = results['messages'].map do |message|
              "(#{message['type']}) #{message['message']}"
            end.join("\n- ")

            "- #{combined_messages}"
          end
        end
      end
    end
  end
end
