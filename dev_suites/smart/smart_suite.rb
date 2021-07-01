require 'hanami-controller'
require 'pry'

class ResumeTestRoute
  include Hanami::Action

  def self.call(params)
    new.call(params)
  end

  def request
    @request ||= Inferno::Entities::Request.from_rack_env(@params.env)
  end

  def test_run
    @test_run ||=
      test_run_repo.find_latest_waiting_by_identifier(test_run_identifier)
  end

  def test_run_repo
    Inferno::Repositories::TestRuns.new
  end

  def results_repo
    Inferno::Repositories::Results.new
  end

  def tests_repo
    Inferno::Repositories::Tests.new
  end

  def waiting_result
    @waiting_result ||= results_repo.find_waiting_result(test_run_id: test_run.id)
  end

  def update_result
    results_repo.update_result_and_message(waiting_result.id, 'pass', nil)
  end

  def persist_request
    Inferno::Repositories::Requests.new.create(
      request.to_hash.merge(
        test_session_id: test_run.test_session_id,
        result_id: waiting_result.id
      )
    )
  end

  def redirect_route
    "/test_sessions/#{test_run.test_session_id}##{waiting_group_id}"
  end

  def waiting_group_id
    tests_repo.find(waiting_result.test_id).parent.id
  end

  def call(_params)
    if test_run.nil?
      status(500, "Unable to find test run with identifier '#{test_run_identifier}'.")
      return
    end

    test_run_repo.update_status_and_identifier(test_run.id, 'running', nil)

    update_result
    persist_request

    redirect_to redirect_route
  end
end

module SMART
  class SMARTSuite < Inferno::TestSuite
    class LaunchRoute < ResumeTestRoute
      def test_run_identifier
        request.query_parameters['iss']
      end
    end

    route :get, '/launch', LaunchRoute

    id 'smart'
    title 'SMART'

    group do
      id 'smart_group'
      title 'SMART Group'

      test do
        id 'auth_redirect'
        title 'OAuth server redirects client browser to app redirect URI'

        run do
          wait(
            identifier: 'abc',
            message: "Waiting to receive a request at /custom/smart/launch with an iss of 'abc'"
          )
        end
      end
    end
  end
end
