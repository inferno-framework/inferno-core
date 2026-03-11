require_relative 'session_results'

module Inferno
  module CLI
    module Session
      class SessionCompare < SessionResults
        def run
          display_compared_results
          if output_directory.present? && !results_match?
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

        # Output directory is the dirname of the expected results file (-f).
        # Returns nil when -f is not provided (e.g. session-to-session comparison),
        # in which case no output files are written on mismatch.
        def output_directory
          options[:expected_results_file].present? && File.dirname(options[:expected_results_file])
        end

        def output_file_prefix
          return '' unless options[:expected_results_file].present?

          basename = File.basename(options[:expected_results_file])
          basename.end_with?('expected.json') ? basename.sub(/expected\.json$/, '') : ''
        end

        def save_actual_results_to_file
          actual_results_file_name = "#{output_file_prefix}actual_results_#{results_timestamp}.json"
          File.write(File.join(output_directory, actual_results_file_name), session_results.to_json)
        end

        def save_comparison_csv_to_file
          compared_csv_file_name = "#{output_file_prefix}compared_results_#{results_timestamp}.csv"
          File.write(File.join(output_directory, compared_csv_file_name),
                     compared_results_as_csv)
        end

        def display_compared_results
          output = {
            matched: results_match?,
            results: compared_results.map(&:to_h)
          }
          puts JSON.pretty_generate(output)
        end

        def compared_results_as_csv
          CSV.generate do |csv|
            csv << comparison_csv_header_row
            compared_results.each do |result|
              next unless result.different_result?

              csv << result.comparison_csv_row
            end
          end
        end

        def comparison_csv_header_row
          header_row = ['id', 'different?', 'expected result', 'actual result']
          if options[:compare_result_message]
            header_row << 'result_message different?'
            header_row << "expected result_message#{' (normalized)' if options[:normalize]}"
            header_row << "actual result_message#{' (normalized)' if options[:normalize]}"
          end
          if options[:compare_messages]
            header_row << 'messages different?'
            header_row << "expected messages#{' (normalized)' if options[:normalize]}"
            header_row << "actual messages#{' (normalized)' if options[:normalize]}"
          end

          header_row
        end

        def results_match?
          compared_results.all?(&:same_result?)
        end

        def expected_results
          @expected_results ||= if options[:expected_results_session].present?
                                  results_for_session(options[:expected_results_session])
                                elsif options[:expected_results_file].present?
                                  JSON.parse(File.read(options[:expected_results_file]))
                                else
                                  puts({ errors: 'No expected results provided.' }.to_json)
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
          # Matches UUIDs and base64/base64url strings of 20+ characters that contain
          # at least one uppercase letter, one lowercase letter, and one digit —
          # the hallmark of randomly generated values (PKCE challenges/verifiers,
          # state parameters, authorization codes, opaque tokens, etc.).
          BASE64_CHARS = '[A-Za-z0-9+\/=_-]'.freeze
          DYNAMIC_VALUE_PATTERNS = [
            [/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/i, '<uuid>'],
            [/(?=#{BASE64_CHARS}*[A-Z])(?=#{BASE64_CHARS}*[a-z])(?=#{BASE64_CHARS}*[0-9])#{BASE64_CHARS}{20,}/,
             '<base64>']
          ].freeze

          attr_reader :id, :expected_result, :actual_result, :options

          def initialize(id, expected_result, actual_result, options)
            @id = id
            @expected_result = expected_result
            @actual_result = actual_result
            @options = options
            @same = same_results?
          end

          def normalize_string(str)
            return str unless options[:normalize] && str.present?

            DYNAMIC_VALUE_PATTERNS.reduce(str) do |s, (pattern, placeholder)|
              s.gsub(pattern, placeholder)
            end
          end

          def same_results?
            return false unless type == 'Compared'
            return false unless expected_result['result'] == actual_result['result']

            if options[:compare_result_message] &&
               normalize_string(expected_result['result_message']) != normalize_string(actual_result['result_message'])
              return false
            end
            return false if options[:compare_messages] && !same_messages?

            true
          end

          def message_comparisons
            @message_comparisons ||= build_message_comparisons
          end

          def build_message_comparisons
            expected_msgs = Array(expected_result&.dig('messages'))
            actual_msgs = Array(actual_result&.dig('messages'))
            max_length = [expected_msgs.size, actual_msgs.size].max
            (0...max_length).map { |i| messages_match?(expected_msgs[i], actual_msgs[i]) }
          end

          def messages_match?(expected_message, actual_message)
            expected_message.present? && actual_message.present? && same_message?(expected_message, actual_message)
          end

          def same_messages?
            return false unless expected_result['messages']&.size == actual_result['messages']&.size
            return true unless expected_result['messages'].present?

            message_comparisons.all?
          end

          def same_message?(expected_message, actual_message)
            expected_message['type'] == actual_message['type'] &&
              normalize_string(expected_message['message']) == normalize_string(actual_message['message'])
          end

          def same_result?
            @same
          end

          def different_result?
            !same_result?
          end

          def different_result_message?
            return false unless type == 'Compared'

            normalize_string(expected_result['result_message']) != normalize_string(actual_result['result_message'])
          end

          def different_messages?
            return false unless type == 'Compared'

            !same_messages?
          end

          def to_h
            {
              id: id,
              type: type,
              matched: same_result?,
              expected_result: expected_result&.dig('result'),
              actual_result: actual_result&.dig('result')
            }.merge(optional_to_h_fields)
          end

          def optional_to_h_fields
            fields = {}
            if options[:compare_result_message]
              fields[:expected_result_message] = expected_result&.dig('result_message')
              fields[:actual_result_message] = actual_result&.dig('result_message')
            end
            if options[:compare_messages]
              fields[:expected_messages] = expected_result&.dig('messages')
              fields[:actual_messages] = actual_result&.dig('messages')
            end
            fields
          end

          def comparison_csv_row
            row = [id, different_result?, expected_result&.dig('result'), actual_result&.dig('result')]
            if options[:compare_result_message]
              row << different_result_message?
              row << expected_result&.dig('result_message')
              row << actual_result&.dig('result_message')
            end
            if options[:compare_messages]
              row << different_messages?
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
            return '' unless results&.dig('messages').present?

            results['messages'].each_with_index.map do |message, index|
              message_text_for_csv(message, index)
            end.join("\n")
          end

          def message_text_for_csv(message, index)
            prefix = message_comparisons[index] ? '- ' : '! '
            text = message['message'].to_s
              .gsub("\r\n", '\n')
              .gsub("\n", '\n')
              .gsub("\r", '\r')
              .gsub("\t", '\t')
            "#{prefix}(#{message['type']}) \"#{text}\""
          end
        end
      end
    end
  end
end
