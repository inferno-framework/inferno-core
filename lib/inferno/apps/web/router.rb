require 'erb'

module Inferno
  module Web
    client_page = ERB.new(File.read(File.join(Inferno::Application.root, 'lib', 'inferno', 'apps', 'web',
                                              'index.html.erb'))).result

    Router = Hanami::Router.new(namespace: Inferno::Web::Controllers) do
      namespace Application['base_path'] do
        namespace 'api' do
          resources 'test_runs', only: [:create, :show, :destroy] do
            resources 'results', only: [:index]
          end

          resources 'test_sessions', only: [:create, :show] do
            resources 'results', only: [:index]
            resources 'session_data', only: [:index] do
              collection do
                put '/apply_preset',
                    to: Inferno::Web::Controllers::TestSessions::SessionData::ApplyPreset,
                    as: :apply_preset
              end
            end
          end
          get 'test_sessions/:test_session_id/last_test_run',
              to: Inferno::Web::Controllers::TestSessions::LastTestRun,
              as: :last_test_run

          resources 'test_suites', only: [:index, :show]
          put 'test_suites/:id/check_configuration',
              to: Inferno::Web::Controllers::TestSuites::CheckConfiguration,
              as: :check_configuration

          resources 'requests', only: [:show]

          get '/version', to: ->(_env) { [200, {}, [{ 'version' => Inferno::VERSION.to_s }.to_json]] }, as: :api_version
        end

        # Should not need Content-Type header but GitHub Codespaces will not work without them.
        # This could be investigated and likely removed if addressed properly elsewhere.
        get '/', to: ->(_env) { [200, { 'Content-Type' => 'text/html' }, [client_page]] }
        get '/test_sessions/:id', to: ->(_env) { [200, { 'Content-Type' => 'text/html' }, [client_page]] }

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
end
