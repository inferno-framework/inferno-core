module ScriptTokens
  # Exercises execution script template token substitution in start_run inputs
  # (see execution_scripts/script_tokens). One session ("provider") waits with an
  # output containing characters that must be escaped in JSON. While it waits, the
  # script starts another session ("consumer") with that value substituted into a
  # .json file input, an inline YAML mapping input, and a .txt file input.
  #
  # Why this shape:
  #   - Only {result_message} and {wait_outputs.KEY} tokens can carry values that need
  #     JSON escaping ({session_id} and {inferno_base_url} never contain quotes or
  #     backslashes), and those tokens are only available while a test is waiting.
  #   - A session with a waiting test cannot start another run (the API returns 409),
  #     so the run that uses the token value has to be in a second session.
  #   - The value is fixed (not derived from the session or base URL) so that the
  #     consumer tests can check it exactly and the expected results are the same in
  #     every environment.
  class Suite < Inferno::TestSuite
    title 'Execution Script Tokens'
    id 'script_tokens'
    short_description 'Exercises execution script token substitution in file and JSON inputs'

    # Contains double quotes and a backslash so that unescaped substitution into
    # a JSON string would produce invalid JSON or a different value.
    TOKEN_VALUE = 'He said "hi" \\ then left'.freeze

    resume_test_route :get, '/resume' do |request|
      request.query_parameters['xyz']
    end

    group do
      id 'provide_value'
      title 'Provide Value'

      test do
        id 'wait_with_value'
        title 'Wait With Value To Substitute'

        output :token_value, :resume_url

        run do
          identifier = SecureRandom.hex(32)
          resume_url = "#{Inferno::Application['base_url']}/custom/script_tokens/resume?xyz=#{identifier}"
          output(token_value: TOKEN_VALUE, resume_url:)
          wait(identifier:, message: 'Waiting for the consumer session to use the token value')
        end
      end
    end

    group do
      id 'use_value'
      title 'Use Value'

      test do
        id 'json_file_input'
        title 'Token Substituted And JSON-Escaped In A .json File Input'

        input :json_file_input

        run do
          note = JSON.parse(json_file_input)['note']
          assert note == TOKEN_VALUE, "Expected note to be #{TOKEN_VALUE.inspect}, but was #{note.inspect}"
          info "json_file_input note: #{note}"
        end
      end

      test do
        id 'json_mapping_input'
        title 'Token Substituted And JSON-Escaped In An Inline YAML Mapping Input'

        input :json_mapping_input

        run do
          note = JSON.parse(json_mapping_input)['note']
          assert note == TOKEN_VALUE, "Expected note to be #{TOKEN_VALUE.inspect}, but was #{note.inspect}"
          info "json_mapping_input note: #{note}"
        end
      end

      test do
        id 'text_file_input'
        title 'Token Substituted Without Escaping In A Non-JSON File Input'

        input :text_file_input

        run do
          expected = "note: #{TOKEN_VALUE}"
          actual = text_file_input.strip
          assert actual == expected, "Expected #{expected.inspect}, but was #{actual.inspect}"
          info "text_file_input: #{actual}"
        end
      end
    end
  end
end
