require 'csv'
require 'cgi'
require 'uri'
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
                  'comparison files will be placed in the same directory. Expected results ' \
                  'files written by execute_script are stored normalized (e.g., with ' \
                  '<NAME.session_id> and <inferno_base_url> placeholders) and are not supported here; ' \
                  'compare those by running the script.'
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
          compare_requests: {
            type: :boolean,
            default: false,
            desc: 'Compare requests (direction, verb, URL, and status) when comparing results. ' \
                  'Normalized strings are applied to the URL.'
          },
          compare_io: {
            type: :boolean,
            default: false,
            desc: 'Compare inputs and outputs (name and value) when comparing results. ' \
                  'Normalized strings are applied to the values.'
          },
          normalized_strings: {
            aliases: ['-n'],
            type: :array,
            desc: 'Literal strings or regexes to normalize away before comparing ' \
                  '(URL-encoded form of literal strings will also be normalized).'
          },
          only_different_messages: {
            aliases: ['-d'],
            type: :boolean,
            default: false,
            desc: 'When displaying messages and requests in CSV output, only show mismatched ones ' \
                  '(hide matching ones).'
          }
        }.freeze

        COMPARED_RESULT_FIELDS = %w[test_id test_group_id test_suite_id result result_message].freeze
        # Compared list field => [fields kept for each entry, field that normalization applies to]
        COMPARED_LIST_FIELDS = {
          'inputs' => [%w[name value], 'value'],
          'outputs' => [%w[name value], 'value'],
          'messages' => [%w[type message], 'message'],
          'requests' => [%w[direction verb url status], 'url']
        }.freeze

        # Inferno replaces large input and output values with a message containing a link that
        # varies by run (result id, session id, and host), so only the fact that the value was
        # large is compared.
        LARGE_IO_VALUE_PATTERN = /\A(Input|Output) is too large to display/
        LARGE_IO_VALUE_SIGNATURE = '<too large to compare>'.freeze
        IO_LIST_FIELDS = %w[inputs outputs].freeze

        # Reduces results to the fields used in comparison and applies normalized_strings, so that
        # stored results (expected results files and actual results written on a mismatch) only
        # change when compared content changes.
        def self.results_for_storage(results, normalized_strings = [])
          results.map do |result|
            stored = result.slice(*COMPARED_RESULT_FIELDS)
            if stored['result_message'].present?
              stored['result_message'] = normalize_string(stored['result_message'], normalized_strings)
            end
            COMPARED_LIST_FIELDS.each do |list_field, (entry_fields, normalized_field)|
              next unless result[list_field].present?

              stored[list_field] = result[list_field].map do |entry|
                stored_entry = entry.slice(*entry_fields)
                stored_entry[normalized_field] =
                  if IO_LIST_FIELDS.include?(list_field)
                    stored_io_value(entry[normalized_field], normalized_strings)
                  else
                    normalize_string(entry[normalized_field], normalized_strings)
                  end
                stored_entry.compact
              end
            end
            stored
          end
        end

        # Inputs and outputs may have non-string or large values (see LARGE_IO_VALUE_PATTERN).
        def self.stored_io_value(value, normalized_strings)
          return if value.nil?

          value = value.to_json unless value.is_a?(String)
          return LARGE_IO_VALUE_SIGNATURE if value.match?(LARGE_IO_VALUE_PATTERN)

          normalize_string(value, normalized_strings)
        end

        # Applies normalized_strings entries to a string. Entries may be:
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
        # The URL-encoded form of plain strings is also replaced.
        def self.normalize_string(str, normalized_strings)
          return str unless str.present?

          normalization_pairs(normalized_strings).reduce(str) do |s, (pattern, replacement)|
            s.gsub(pattern, replacement)
          end
        end

        # [pattern, replacement] pairs for normalized_strings, parsed once per list of rules since
        # normalize_string is called many times per comparison (e.g., while aligning messages).
        # Plain strings yield a second pair for their URL-encoded form.
        def self.normalization_pairs(normalized_strings)
          @normalization_pairs ||= {}
          @normalization_pairs[normalized_strings] ||= Array(normalized_strings).flat_map do |entry|
            parse_normalize_entry(entry).flat_map do |pattern, replacement|
              patterns = pattern.is_a?(Regexp) ? [pattern] : [pattern, CGI.escape(pattern)]
              patterns.map { |each_pattern| [each_pattern, replacement] }
            end
          end
        end

        # Parses a normalized_strings entry into an array of [pattern, replacement] pairs.
        def self.parse_normalize_entry(entry)
          if entry.is_a?(Hash)
            replacement = entry.fetch('replacement', '<NORMALIZED>')
            Array(entry['patterns'] || entry['pattern']).map do |pattern|
              [parse_pattern_string(pattern.to_s), replacement]
            end
          else
            [[parse_pattern_string(entry.to_s), '<NORMALIZED>']]
          end
        end

        def self.parse_pattern_string(str)
          return str unless (parsed_regex = str.match(%r{\A/(.+)/([imx]*)\z}m))

          flags = 0
          flags |= Regexp::IGNORECASE if parsed_regex[2].include?('i')
          flags |= Regexp::MULTILINE  if parsed_regex[2].include?('m')
          flags |= Regexp::EXTENDED   if parsed_regex[2].include?('x')
          Regexp.new(parsed_regex[1], flags)
        end

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
          actual_results_file_name = "#{output_file_prefix}actual_results_#{results_timestamp}#{host_suffix}.json"
          File.write(File.join(output_directory, actual_results_file_name),
                     JSON.pretty_generate(
                       self.class.results_for_storage(session_results, options[:normalized_strings])
                     ))
        end

        def save_comparison_csv_to_file
          compared_csv_file_name = "#{output_file_prefix}compared_results_#{results_timestamp}#{host_suffix}.csv"
          File.write(File.join(output_directory, compared_csv_file_name),
                     compared_results_as_csv)
        end

        # Filesystem-safe "_<host>" (plus non-default port, if any) suffix derived from
        # the --inferno-base-url (-I) option, so output filenames can be disambiguated
        # by target server. Empty when -I was not passed or the URL has no host.
        def host_suffix
          inferno_host_slug ? "_#{inferno_host_slug}" : ''
        end

        def inferno_host_slug
          return nil unless options[:inferno_base_url].present?

          uri = begin
            URI.parse(options[:inferno_base_url])
          rescue URI::InvalidURIError
            nil
          end
          host = uri&.host
          return nil unless host

          slug = host.dup
          slug << "_#{uri.port}" if uri.port && uri.port != uri.default_port
          slug.gsub(/[^a-zA-Z0-9.-]/, '_')
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
          if options[:compare_requests]
            header_row << 'requests different?'
            header_row << "expected requests#{normalized_suffix}"
            header_row << "actual requests#{normalized_suffix}"
          end
          if options[:compare_io]
            header_row << 'inputs/outputs different?'
            header_row << "expected inputs/outputs#{normalized_suffix}"
            header_row << "actual inputs/outputs#{normalized_suffix}"
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

          def normalize_string(str)
            SessionCompare.normalize_string(str, options[:normalized_strings])
          end

          # Option enabling each optional comparison => method checking that it matches
          OPTIONAL_COMPARISONS = {
            compare_result_message: :same_result_message?,
            compare_messages: :same_messages?,
            compare_requests: :same_requests?,
            compare_io: :same_io?
          }.freeze

          def same_results?
            return false unless type == 'Compared'
            return false unless expected_result['result'] == actual_result['result']

            OPTIONAL_COMPARISONS.all? { |option, check| !options[option] || send(check) }
          end

          def same_result_message?
            normalize_string(expected_result['result_message']) == normalize_string(actual_result['result_message'])
          end

          # A request is compared by its direction, verb, URL, and response status.
          # Normalized strings are applied to the URL.
          def request_signature(request)
            [
              request['direction'],
              request['verb'].to_s.upcase,
              normalize_string(request['url'].to_s),
              request['status']
            ].join(' ')
          end

          def sorted_request_signatures(result)
            Array(result&.dig('requests')).map { |request| request_signature(request) }.sort
          end

          # Requests are compared as an unordered collection since concurrent requests
          # may be recorded in a different order between runs.
          def request_comparisons
            @request_comparisons ||= unordered_comparisons(
              sorted_request_signatures(expected_result), sorted_request_signatures(actual_result)
            )
          end

          # An input or output is compared by its name and value, normalized as when stored.
          def io_signature(kind, entry)
            "#{kind} #{entry['name']}: #{SessionCompare.stored_io_value(entry['value'], options[:normalized_strings])}"
          end

          def sorted_io_signatures(result)
            (Array(result&.dig('inputs')).map { |input| io_signature('input', input) } +
              Array(result&.dig('outputs')).map { |output| io_signature('output', output) }).sort
          end

          # Inputs and outputs are compared as an unordered collection.
          def io_comparisons
            @io_comparisons ||=
              unordered_comparisons(sorted_io_signatures(expected_result), sorted_io_signatures(actual_result))
          end

          def same_io?
            io_comparisons.all? { |entry| entry[:expected] && entry[:actual] }
          end

          def different_io?
            return false unless type == 'Compared'

            !same_io?
          end

          # Returns [{ signature:, expected: bool, actual: bool }] sorted by signature,
          # where an entry is matched when it is present on both sides.
          def unordered_comparisons(expected_signatures, actual_signatures)
            expected_counts = expected_signatures.tally
            actual_counts = actual_signatures.tally
            (expected_counts.keys | actual_counts.keys).sort.flat_map do |signature|
              expected_count = expected_counts.fetch(signature, 0)
              actual_count = actual_counts.fetch(signature, 0)
              Array.new([expected_count, actual_count].max) do |index|
                { signature:, expected: index < expected_count, actual: index < actual_count }
              end
            end
          end

          def same_requests?
            request_comparisons.all? { |entry| entry[:expected] && entry[:actual] }
          end

          def different_requests?
            return false unless type == 'Compared'

            !same_requests?
          end

          def message_comparisons
            @message_comparisons ||= build_message_comparisons
          end

          MESSAGE_TYPE_ORDER = { 'error' => 0, 'warning' => 1, 'info' => 2 }.freeze
          UNKNOWN_MESSAGE_TYPE_ORDER = 99

          def build_message_comparisons
            lcs_align(sorted_messages(expected_result), sorted_messages(actual_result))
          end

          def lcs_align(expected, actual)
            lcs_backtrack(lcs_matrix(expected, actual), expected, actual)
          end

          def lcs_matrix(expected, actual)
            matrix = Array.new(expected.size + 1) { Array.new(actual.size + 1, 0) }
            (1..expected.size).each do |expected_index|
              (1..actual.size).each do |actual_index|
                matrix[expected_index][actual_index] =
                  if same_message?(expected[expected_index - 1], actual[actual_index - 1])
                    matrix[expected_index - 1][actual_index - 1] + 1
                  else
                    [matrix[expected_index - 1][actual_index],
                     matrix[expected_index][actual_index - 1]].max
                  end
              end
            end
            matrix
          end

          def lcs_backtrack(matrix, expected, actual)
            alignment = []
            expected_index = expected.size
            actual_index = actual.size

            while expected_index.positive? || actual_index.positive?
              step = lcs_backtrack_step(matrix, expected, actual, expected_index, actual_index)
              alignment.unshift(step[:entry])
              expected_index = step[:next_expected_index]
              actual_index = step[:next_actual_index]
            end
            alignment
          end

          # Each step returns { entry:, next_expected_index:, next_actual_index: }.
          # entry is { expected: msg_or_nil, actual: msg_or_nil, match: bool }.
          def lcs_backtrack_step(matrix, expected, actual, expected_index, actual_index)
            if expected_index.positive? &&
               actual_index.positive? &&
               same_message?(expected[expected_index - 1], actual[actual_index - 1])

              # Items match: consume both
              entry = { expected: expected[expected_index - 1], actual: actual[actual_index - 1], match: true }
              { entry:, next_expected_index: expected_index - 1, next_actual_index: actual_index - 1 }
            elsif actual_index.positive? &&
                  (expected_index.zero? ||
                   matrix[expected_index][actual_index - 1] >= matrix[expected_index - 1][actual_index])
              # Item in actual is "Additional": consume only actual
              { entry: { expected: nil, actual: actual[actual_index - 1], match: false },
                next_expected_index: expected_index,
                next_actual_index: actual_index - 1 }
            else
              # Item in expected is "Missing": consume only expected
              { entry: { expected: expected[expected_index - 1], actual: nil, match: false },
                next_expected_index: expected_index - 1,
                next_actual_index: actual_index }
            end
          end

          def sorted_messages(result)
            Array(result&.dig('messages')).sort_by do |m|
              [MESSAGE_TYPE_ORDER.fetch(m['type'].to_s, UNKNOWN_MESSAGE_TYPE_ORDER),
               normalize_string(m['message'].to_s)]
            end
          end

          def same_messages?
            message_comparisons.all? { |entry| entry[:match] }
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
            # Both sides are shown normalized, since expected results are stored normalized
            if options[:compare_result_message]
              fields[:expected_result_message] = normalize_string(expected_result&.dig('result_message'))
              fields[:actual_result_message] = normalize_string(actual_result&.dig('result_message'))
            end
            if options[:compare_messages]
              fields[:expected_messages] = normalized_messages(expected_result)
              fields[:actual_messages] = normalized_messages(actual_result)
            end
            fields.merge(requests_to_h_fields, io_to_h_fields)
          end

          def normalized_messages(result)
            result&.dig('messages')&.map { |message| message.merge('message' => normalize_string(message['message'])) }
          end

          def requests_to_h_fields
            return {} unless options[:compare_requests]

            {
              expected_requests: expected_result && sorted_request_signatures(expected_result),
              actual_requests: actual_result && sorted_request_signatures(actual_result)
            }
          end

          def io_to_h_fields
            return {} unless options[:compare_io]

            {
              expected_io: expected_result && sorted_io_signatures(expected_result),
              actual_io: actual_result && sorted_io_signatures(actual_result)
            }
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
            row.concat(requests_csv_columns, io_csv_columns)
          end

          def requests_csv_columns
            return [] unless options[:compare_requests]

            [different_requests?,
             format_unordered_comparisons_for_csv(request_comparisons, :expected),
             format_unordered_comparisons_for_csv(request_comparisons, :actual)]
          end

          def io_csv_columns
            return [] unless options[:compare_io]

            [different_io?,
             format_unordered_comparisons_for_csv(io_comparisons, :expected),
             format_unordered_comparisons_for_csv(io_comparisons, :actual)]
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

            is_expected = results == expected_result
            lines = message_comparisons.filter_map { |entry| message_line_for_csv(entry, is_expected) }
            collapse_message_lines(lines).join("\n")
          end

          def message_line_for_csv(entry, is_expected)
            return if options[:only_different_messages] && entry[:match]

            msg = is_expected ? entry[:expected] : entry[:actual]
            return if msg.nil?

            message_text_for_csv(msg, entry[:match])
          end

          def collapse_message_lines(lines)
            lines.chunk_while { |a, b| a == b }.map do |group|
              group.size > 1 ? "(#{group.size}) #{group.first}" : group.first
            end
          end

          def format_unordered_comparisons_for_csv(comparisons, side)
            lines = comparisons.filter_map do |entry|
              next unless entry[side]

              matches = entry[:expected] && entry[:actual]
              next if options[:only_different_messages] && matches

              "#{matches ? '- ' : '! '}#{entry[:signature]}"
            end
            collapse_message_lines(lines).join("\n")
          end

          def message_text_for_csv(message, matches)
            prefix = matches ? '- ' : '! '
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
