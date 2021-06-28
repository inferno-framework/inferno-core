require 'hanami-controller'
require 'pry'
require 'sinatra/base'

module SMART
  class SMARTSuite < Inferno::TestSuite
    class LaunchRoute
      include Hanami::Action

      def self.call(params)
        new.call(params)
      end

      def call(params)
        iss = params.get(:iss)
        repo = Inferno::Repositories::TestRuns.new
        repo.find_latest_by_suite_and_input(test_suite_id: 'smart', input_name: 'url', input_value: 'iss')
        binding.pry
        self.body = 'ExampleRoute Response'
      end
    end

    route :get, '/launch', LaunchRoute

    id 'smart'
  end
end
