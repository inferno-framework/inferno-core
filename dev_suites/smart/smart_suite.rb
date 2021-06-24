require 'hanami-controller'
require 'pry'
require 'sinatra/base'

module SMART
  class SMARTSuite < Inferno::TestSuite
    class ExampleController
      include Hanami::Action

      def self.call(params)
        new.call(params)
      end

      def call(_params)
        self.body = 'ExampleRoute Response'
      end
    end

    class ExampleApp < Sinatra::Base
      get '/' do
        'App Response'
      end

      get '/2' do
        'App Response 2'
      end
    end

    id 'smart'

    route :get, '/proc', ->(_env) { [200, {}, ['Proc Response']] }

    route :get, '/controller', ExampleController

    route :all, '/app', ExampleApp
  end
end
