require_relative 'session/cancel_run'
require_relative 'session/create_session'
require_relative 'session/start_run'
require_relative 'session/session_status'
require_relative 'session/session_results'
require_relative 'session/session_data'
require_relative 'session/session_compare'

module Inferno
  module CLI
    module Session
      class SessionCommands < Thor
        desc 'create SUITE_ID', 'Create a new session for a suite.'
        option :inferno_base_url,
               aliases: ['-I'],
               type: :string,
               desc: 'URL of the target Inferno service.'
        option :suite_options,
               aliases: ['-o'],
               type: :hash,
               desc: 'Suite options used to initialize the session.'
        option :preset_id,
               aliases: ['-p'],
               type: :string,
               desc: 'Preset to apply when creating the session.'
        def create(suite_id)
          CreateSession.new(suite_id, options).run
        end

        desc 'cancel_run SESSION_ID', 'Cancel the current in-progress run for a session.'
        option :inferno_base_url,
               aliases: ['-I'],
               type: :string,
               desc: 'URL of the target Inferno service.'
        def cancel_run(session_id)
          CancelRun.new(session_id, options).run
        end

        desc 'start_run SESSION_ID', 'Initiate a test run on a session.'
        option :inferno_base_url,
               aliases: ['-I'],
               type: :string,
               desc: 'URL of the target Inferno service.'
        option :runnable,
               aliases: ['-r'],
               type: :string,
               desc: 'Which runnable to execute. Must be a single group or test id (can be short or internal). ' \
                     'If not present, the whole suite will be executed.'
        option :inputs,
               aliases: ['-i'],
               type: :hash,
               desc: 'Inputs (i.e: --inputs=foo:bar goo:baz); will merge and override current session inputs ' \
                     '(from preset or previous runs)'
        def start_run(session_id)
          StartRun.new(session_id, options).run
        end

        desc 'status SESSION_ID', 'Get the current run status of a session.'
        option :inferno_base_url,
               aliases: ['-I'],
               type: :string,
               desc: 'URL of the target Inferno service.'
        def status(session_id)
          SessionStatus.new(session_id, options).run
        end

        desc 'data SESSION_ID', 'Get the current session data (inputs) for a session.'
        option :inferno_base_url,
               aliases: ['-I'],
               type: :string,
               desc: 'URL of the target Inferno service.'
        def data(session_id)
          SessionData.new(session_id, options).run
        end

        desc 'results SESSION_ID', 'Get the results for a session.'
        option :inferno_base_url,
               aliases: ['-I'],
               type: :string,
               desc: 'URL of the target Inferno service.'
        def results(session_id)
          SessionResults.new(session_id, options).run
        end

        desc 'compare SESSION_ID',
             'Compare the results of a session to expected results (from file or another session).'
        option :inferno_base_url,
               aliases: ['-I'],
               type: :string,
               desc: 'URL of the target Inferno service.'
        option :expected_results_session,
               aliases: ['-s'],
               type: :string,
               desc: 'Session id on the same server that contains the expected results.'
        option :expected_results_file,
               aliases: ['-f'],
               type: :string,
               desc: 'Path to a file that contains the expected results.'
        option :compare_messages,
               aliases: ['-m'],
               type: :boolean,
               default: false,
               desc: 'Compare messages when comparing results.'
        option :compare_result_message,
               aliases: ['-r'],
               type: :boolean,
               default: false,
               desc: 'Compare result_message when comparing results.'
        option :normalize,
               aliases: ['-n'],
               type: :boolean,
               default: false,
               desc: 'Normalize dynamic values (UUIDs, base64url strings) before comparing strings.'
        def compare(session_id)
          SessionCompare.new(session_id, options).run
        end
      end
    end
  end
end
