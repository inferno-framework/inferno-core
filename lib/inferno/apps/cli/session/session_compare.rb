require 'csv'
require 'cgi'
require_relative 'session_details'
require_relative 'session_results'

module Inferno
  module CLI
    module Session
      class SessionCompare < SessionResults
        COMMAND_OPTIONS = {
          expected_results_session: {
            aliases: ['-s'],
            type: :string,
            desc: 'Session ID on the same server. The results of this indicated ' \
                  'session will be used as the expected results. When the compared ' \
                  "session's results do not match, comparison details will not be " \
                  'written to file (use the `-f` option).'
          },
          expected_results_file: {
            aliases: ['-f'],
            type: :string,
            desc: 'Path to a file that contains the expected results. When the session ' \
                  'results do not match the expected results in the file, generated ' \
                  'comparison files will be placed in the same directory.'
          },
          compare_messages: {
            aliases: ['-m'],
            type: :boolean,
            default: false,
            desc: 'Compare messages when comparing results.'
          },
          compare_result_message: {
            aliases: ['-r'],
            type: :boolean,
            default: false,
            desc: 'Compare result_message when comparing results.'
          },
          normalized_strings: {
            aliases: ['-n'],
            type: :array,
            desc: 'Literal strings or regexes to normalize away before comparing ' \
                  '(URL-encoded form of literal strings will also be normalized).'
          }
        }.freeze
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

        def normalizing?
          options[:normalized_strings].present?
        end

        def comparison_csv_header_row
          normalized_suffix = normalizing? ? ' (normalized)' : ''
          header_row = ['id', 'short_id', 'type', 'different?', 'expected result', 'actual result']
          if options[:compare_result_message]
            header_row << 'result_message different?'
            header_row << "expected result_message#{normalized_suffix}"
            header_row << "actual result_message#{normalized_suffix}"
          end
          if options[:compare_messages]
            header_row << 'messages different?'
            header_row << "expected messages#{normalized_suffix}"
            header_row << "actual messages#{normalized_suffix}"
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

        def session_details
          @session_details ||= SessionDetails.new(session_id, options).details_for_session
        end

        def short_id_map
          @short_id_map ||= build_short_id_map(session_details['test_suite'])
        end

        def build_short_id_map(runnable, map = {})
          return map unless runnable.is_a?(Hash)

          map[runnable['id']] = runnable['short_id'] if runnable['id'].present?
          runnable['test_groups']&.each { |group| build_short_id_map(group, map) }
          runnable['tests']&.each { |test| build_short_id_map(test, map) }
          map
        end

        def match_result_ids(expected, actual)
          expected_hash = results_hash_by_id(expected)
          actual_hash = results_hash_by_id(actual)

          compared_results = expected_hash.map do |id, result|
            ComparedTestResult.new(id, result, actual_hash[id], options, short_id_map)
          end
          actual_hash.keys.reject { |id| expected_hash.key?(id) }.each do |id|
            compared_results << ComparedTestResult.new(id, nil, actual_hash[id], options, short_id_map)
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
          attr_reader :id, :expected_result, :actual_result, :options, :short_id_map

          def initialize(id, expected_result, actual_result, options, short_id_map = {})
            @id = id
            @expected_result = expected_result
            @actual_result = actual_result
            @options = options
            @short_id_map = short_id_map
            @same = same_results?
          end

          def short_id
            short_id_map[id]
          end

          # Parses a normalize entry into an array of [pattern, replacement] pairs.
          # Entries may be:
          #   - A plain string: literal match, replacement defaults to '<NORMALIZED>'
          #   - A "/pattern/[flags]" string: compiled to Regexp, replacement defaults to '<NORMALIZED>'
          #   - A hash with 'pattern' or 'patterns' and optional 'replacement' keys (from YAML):
          #       pattern: '/code_challenge=[A-Za-z0-9+\/=_-]{20,}/'
          #       replacement: '<CODE_CHALLENGE>'
          #     Or multiple patterns sharing one replacement:
          #       patterns:
          #         - '/code_challenge=[A-Za-z0-9+\/=_-]{20,}/'
          #         - '/code_verifier=[A-Za-z0-9+\/=_-]{20,}/'
          #       replacement: '<PKCE_VALUE>'
          def parse_normalize_entry(entry)
            if entry.is_a?(Hash)
              replacement = entry.fetch('replacement', '<NORMALIZED>')
              Array(entry['patterns'] || entry['pattern']).map do |pattern|
                [parse_pattern_string(pattern.to_s), replacement]
              end
            else
              [[parse_pattern_string(entry.to_s), '<NORMALIZED>']]
            end
          end

          def parse_pattern_string(str)
            return str unless (parsed_regex = str.match(%r{\A/(.+)/([imx]*)\z}m))

            flags = 0
            flags |= Regexp::IGNORECASE if parsed_regex[2].include?('i')
            flags |= Regexp::MULTILINE  if parsed_regex[2].include?('m')
            flags |= Regexp::EXTENDED   if parsed_regex[2].include?('x')
            Regexp.new(parsed_regex[1], flags)
          end

          def normalize_string(str)
            return str unless str.present?

            Array(options[:normalized_strings]).reduce(str) do |s, entry|
              parse_normalize_entry(entry).reduce(s) do |s2, (pattern, replacement)|
                if pattern.is_a?(Regexp)
                  s2.gsub(pattern, replacement)
                else
                  s2.gsub(pattern, replacement).gsub(CGI.escape(pattern), replacement)
                end
              end
            end
          end

          def normalizing?
            options[:normalized_strings].present?
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

          MESSAGE_TYPE_ORDER = { 'error' => 0, 'warning' => 1, 'info' => 2 }.freeze
          UNKNOWN_MESSAGE_TYPE_ORDER = 99

          def build_message_comparisons
            expected_msgs = sorted_messages(expected_result)
            actual_msgs = sorted_messages(actual_result)
            max_length = [expected_msgs.size, actual_msgs.size].max
            (0...max_length).map { |i| messages_match?(expected_msgs[i], actual_msgs[i]) }
          end

          def sorted_messages(result)
            Array(result&.dig('messages')).sort_by do |m|
              [MESSAGE_TYPE_ORDER.fetch(m['type'].to_s, UNKNOWN_MESSAGE_TYPE_ORDER),
               normalize_string(m['message'].to_s)]
            end
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
            row = [id, short_id, type, different_result?, expected_result&.dig('result'), actual_result&.dig('result')]
            if options[:compare_result_message]
              row << different_result_message?
              row << normalize_string(expected_result&.dig('result_message'))
              row << normalize_string(actual_result&.dig('result_message'))
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

            sorted_messages(results).each_with_index.map do |message, index|
              message_text_for_csv(message, index)
            end.join("\n")
          end

          def message_text_for_csv(message, index)
            prefix = message_comparisons[index] ? '- ' : '! '
            text = normalize_string(message['message'].to_s)
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
