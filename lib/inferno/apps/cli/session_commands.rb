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
        def initialize(args = [], local_options = {}, config = {})
          super
          return unless @options[:inferno_base_url]

          @options = @options.merge(inferno_base_url: "#{@options[:inferno_base_url].delete_suffix('/')}/")
        end

        class_option :inferno_base_url,
                     aliases: ['-I'],
                     type: :string,
                     desc: 'URL of the target Inferno service.'

        desc 'create SUITE', 'Create a new session for a suite (internal ID, title, or short title).'
        CreateSession::COMMAND_OPTIONS.each { |name, opts| option name, **opts }
        def create(suite_id)
          CreateSession.new(suite_id, options).run
        end

        desc 'cancel_run SESSION_ID', 'Cancel the current in-progress run for a session.'
        def cancel_run(session_id)
          CancelRun.new(session_id, options).run
        end

        desc 'start_run SESSION_ID RUNNABLE_ID', 'Initiate a test run on a session.'
        StartRun::COMMAND_OPTIONS.each { |name, opts| option name, **opts }
        def start_run(session_id, runnable_id)
          StartRun.new(session_id, options.merge(runnable: runnable_id)).run
        end

        desc 'status SESSION_ID', 'Get the current run status of a session.'
        def status(session_id)
          SessionStatus.new(session_id, options).run
        end

        desc 'data SESSION_ID', 'Get the current session data (inputs) for a session.'
        def data(session_id)
          SessionData.new(session_id, options).run
        end

        desc 'results SESSION_ID', 'Get the results for a session.'
        def results(session_id)
          SessionResults.new(session_id, options).run
        end

        desc 'compare SESSION_ID',
             'Compare the results of a session to expected results (from file or another session).'
        SessionCompare::COMMAND_OPTIONS.each { |name, opts| option name, **opts }
        def compare(session_id)
          SessionCompare.new(session_id, options).run
        end
      end
    end
  end
end
