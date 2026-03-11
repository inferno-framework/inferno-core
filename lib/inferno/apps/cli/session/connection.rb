module Inferno
  module CLI
    module Session
      module Connection
        def connection
          @connection ||= Faraday.new(
            base_url,
            request: { timeout: 600 }
          )
        end

        def base_url
          @base_url ||= if options[:inferno_base_url].present?
                          options[:inferno_base_url]
                        else
                          Inferno::Application['base_url']
                        end
        end
      end
    end
  end
end
