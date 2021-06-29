require 'hanami-controller'
require 'pry'

class CustomRoute
  include Hanami::Action

  def self.call(params)
    new.call(params)
  end

  def request
    @request ||= Inferno::Entities::Request.from_rack_env(@params.env)
  end

  def find_test_run
    Inferno::Repositories::TestRuns.new.find_latest_waiting_by_suite_and_identifier(
      test_suite_id: 'smart',
      identifier: test_run_identifier
    )
  end

  def handle_request; end

  def results_repo
    Inferno::Repositories::Results.new
  end

  def waiting_result
    @waiting_result ||= results_repo.find_waiting_result(test_run_id: test_run.id)
  end

  def update_result
    results_repo.update_status(waiting_result.id, 'pass')
  end

  def persist_request
    Inferno::Repositories::Requests.new.create(
      request.to_hash.merge(
        test_session_id: test_run.test_session_id,
        result_id: waiting_result.id
      )
    )
  end

  def set_response
    self.body = request.response_body
    response_headers = request.response_headers.each_with_object({}) do |header, header_hash|
      header_hash[header.name] = header.value
    end
    headers.merge!(response_headers)
    request.status ||= 200
    self.status = request.status
  end

  def call(_params)
    test_run = find_test_run
    if test_run.nil?
      status(500, "Unable to find test run with identifier '#{test_run_identifier}'.")
      return
    end

    test_run.update_status_and_clear_identifier(test_run.id, 'running')

    handle_request
    set_response

    update_result
    persist_request

    # resume execution with request
  end
end

module SMART
  class SMARTSuite < Inferno::TestSuite
    class LaunchRoute < CustomRoute
      def test_run_identifier
        request.query_parameters['iss']
      end

      def handle_request
        request.response_body = 'LaunchRoute response body'
        request.add_response_header('X-ABC', 'DEF')
        request.status = 201
      end
    end

    route :get, '/launch', LaunchRoute

    id 'smart'
  end
end
