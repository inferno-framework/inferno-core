require 'base62-rb'
require_relative 'repository'

module Inferno
  module Repositories
    class ValidatorSessions < Repository
      def save(params)
        validator_session_id = params[:validator_session_id]
        validator_name = params[:validator_name]
        test_suite_id = params[:test_suite_id]
        raw_suite_options = params[:suite_options]
        time = Time.now

        suite_options =
          if raw_suite_options.blank?
            '[]'
          else
            raw_suite_options.sort.to_s
          end

        db.insert_conflict(
          target: [:test_suite_id,
                   :suite_options,
                   :validator_name],
          update: { validator_session_id:,
                    test_suite_id:,
                    suite_options:,
                    validator_name: }
        ).insert(
          id: "#{validator_session_id}_#{validator_name}",
          validator_session_id:,
          test_suite_id:,
          validator_name:,
          suite_options:,
          last_accessed: time
        )
      end

      def find_validator_session_id(test_suite_id, validator_name, suite_options)
        suite_options = suite_options.nil? ? '[]' : suite_options.sort.to_s
        session = self.class::Model
          .find(test_suite_id:, validator_name:, suite_options:)
        return nil if session.nil?

        time = Time.now
        session.update(last_accessed: time)
        session[:validator_session_id]
      end

      class Model < Sequel::Model(db)
        def before_save
          time = Time.now
          self.last_accessed ||= time
        end
      end
    end
  end
end
