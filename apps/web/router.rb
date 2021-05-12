require 'erb'

module Inferno
  module Web
    client_page = ERB.new(File.read("#{Inferno::Application.root}/apps/web/index.html.erb")).result

    Router = Hanami::Router.new(namespace: Inferno::Web::Controllers) do
      namespace 'api' do
        resources 'test_runs', only: [:create, :show] do
          resources 'results', only: [:index]
        end

        resources 'test_sessions', only: [:create, :show] do
          resources 'results', only: [:index]
        end

        resources 'test_suites', only: [:index, :show]

        resources 'requests', only: [:show]
      end

      get '/', to: ->(_env) { [200, {}, [client_page]] }
      get '/test_sessions/:id', to: ->(_env) { [200, {}, [client_page]] }
    end
  end
end
