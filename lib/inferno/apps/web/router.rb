require 'erb'

module Inferno
  module Web
    client_page = ERB.new(File.read(File.join(Inferno::Application.root, 'lib', 'inferno', 'apps', 'web',
                                              'index.html.erb'))).result

    Router = Hanami::Router.new(namespace: Inferno::Web::Controllers) do
      namespace 'api' do
        resources 'test_runs', only: [:create, :show] do
          resources 'results', only: [:index]
        end

        resources 'test_sessions', only: [:create, :show] do
          resources 'results', only: [:index]
        end
        get 'test_sessions/:test_session_id/last_test_run',
            to: Inferno::Web::Controllers::TestSessions::LastTestRun,
            as: :last_test_run

        resources 'test_suites', only: [:index, :show]

        resources 'requests', only: [:show]
      end

      get '/', to: ->(_env) { [200, {}, [client_page]] }
      get '/test_sessions/:id', to: ->(_env) { [200, {}, [client_page]] }

      Inferno.routes.each do |route|
        cleaned_id = route[:suite].id.gsub(/[^a-zA-Z\d\-._~]/, '_')
        path = "/custom/#{cleaned_id}#{route[:path]}"
        Application['logger'].info("Registering custom route: #{path}")
        if route[:method] == :all
          mount route[:handler], at: path
        else
          send(route[:method], path, to: route[:handler])
        end
      end
    end
  end
end
