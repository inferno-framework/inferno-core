require 'erb'
require 'kramdown'
require 'kramdown-parser-gfm'
require_relative '../../feature'
require_relative '../../repositories/test_kits'

Dir.glob(File.join(__dir__, 'controllers', '**', '*.rb')).each { |path| require_relative path }

module Inferno
  module Web
    client_page = ERB.new(
      File.read(
        File.join(Inferno::Application.root, 'lib', 'inferno', 'apps', 'web', 'templates', 'client_index.html.erb')
      )
    ).result

    test_kit_template = ERB.new(File.read(File.join(__dir__, 'templates', 'test_kit.html.erb')))
    CLIENT_PAGE_RESPONSE = ->(_env) { [200, { 'Content-Type' => 'text/html' }, [client_page]] }

    base_path = Application['base_path']&.delete_prefix('/')

    route_block = proc do
      scope 'api' do
        scope 'test_runs' do
          post '/', to: Inferno::Web::Controllers::TestRuns::Create, as: :create
          get '/:id', to: Inferno::Web::Controllers::TestRuns::Show, as: :show
          delete '/:id', to: Inferno::Web::Controllers::TestRuns::Destroy, as: :destroy

          get ':id/results', to: Inferno::Web::Controllers::TestRuns::Results::Index, as: :results
        end

        scope 'test_sessions' do
          post '/', to: Inferno::Web::Controllers::TestSessions::Create, as: :create
          get '/:id', to: Inferno::Web::Controllers::TestSessions::Show, as: :show

          get '/:id/last_test_run',
              to: Inferno::Web::Controllers::TestSessions::LastTestRun,
              as: :last_test_run
          get '/:id/results',
              to: Inferno::Web::Controllers::TestSessions::Results::Index,
              as: :results
          get '/:id/results/:result_id/io/:type/:name',
              to: Inferno::Web::Controllers::TestSessions::Results::IoValue,
              as: :result_io_value
          get '/:id/session_data',
              to: Inferno::Web::Controllers::TestSessions::SessionData::Index
          put '/:id/session_data/apply_preset',
              to: Inferno::Web::Controllers::TestSessions::SessionData::ApplyPreset,
              as: :session_data_apply_preset
        end

        scope 'test_suites' do
          get '/', to: Inferno::Web::Controllers::TestSuites::Index, as: :index
          get '/:id', to: Inferno::Web::Controllers::TestSuites::Show, as: :show

          put '/:id/check_configuration',
              to: Inferno::Web::Controllers::TestSuites::CheckConfiguration,
              as: :check_configuration
          get ':id/requirements',
              to: Inferno::Web::Controllers::TestSuites::Requirements::Index,
              as: :requirements
        end

        scope 'requirements' do
          get '/:id', to: Inferno::Web::Controllers::Requirements::Show, as: :show
        end

        get '/requests/:id', to: Inferno::Web::Controllers::Requests::Show, as: :requests_show

        get '/version', to: lambda { |_env|
          [200, { 'Content-Type' => 'application/json' }, [{ 'version' => Inferno::VERSION.to_s }.to_json]]
        }, as: :version
      end

      # Should not need Content-Type header but GitHub Codespaces will not work without them.
      # This could be investigated and likely removed if addressed properly elsewhere.
      get '/',
          to: lambda { |env|
            local_test_kit = Inferno::Repositories::TestKits.new.local_test_kit
            if local_test_kit.present?
              base = Inferno::Application['base_path'].present? ? "/#{Inferno::Application['base_path']}" : ''
              [
                302,
                {
                  'Cache-Control' => 'no-cache',
                  'Location' => "#{base}/#{local_test_kit.url_fragment}"
                },
                []
              ]
            else
              CLIENT_PAGE_RESPONSE.call(env)
            end
          }
      get '/jwks.json', to: lambda { |_env|
                              [200, { 'Content-Type' => 'application/json' }, [Inferno::JWKS.jwks_json]]
                            }, as: :jwks

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

      Inferno::Repositories::TestSuites.all.map { |suite| "/#{suite.id}" }.each do |suite_path|
        Application['logger'].info("Registering suite route: #{suite_path}")
        get suite_path, to: lambda { |env|
          test_kit = Inferno::Repositories::TestKits.new.test_kit_for_suite(suite_path.delete_prefix('/'))
          if test_kit.present?
            [200, { 'Content-Type' => 'text/html' }, [test_kit_template.result_with_hash(test_kit:)]]
          else
            CLIENT_PAGE_RESPONSE.call(env)
          end
        }
      end

      Inferno::Repositories::TestKits.all.each do |test_kit|
        Application['logger'].info("Registering test kit route: /#{test_kit.url_fragment}")
        get "/#{test_kit.url_fragment}",
            to: ->(_env) { [200, { 'Content-Type' => 'text/html' }, [test_kit_template.result_with_hash(test_kit:)]] }
      end

      get '/test_sessions/:id', to: Inferno::Web::Controllers::TestSessions::ClientShow, as: :client_session_show
      get '/:test_suite_id/:id', to: Inferno::Web::Controllers::TestSessions::ClientShow, as: :client_suite_session_show

      post '/:test_suite_id', to: Inferno::Web::Controllers::TestSessionFormPostController, as: :session_form_post
    end

    Router = # rubocop:disable Naming/ConstantName
      if base_path.present?
        Hanami::Router.new do
          scope("#{base_path}/") do
            get '/', to: CLIENT_PAGE_RESPONSE
          end
          scope(base_path, &route_block)
        end
      else
        Hanami::Router.new(&route_block)
      end
  end
end
