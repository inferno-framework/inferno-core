require_relative '../../utils/migration'

module Inferno
  module CLI
    class Migration
      def run(log_level = Logger::DEBUG)
        Inferno::Application.start(:logging)
        Inferno::Application['logger'].level = log_level

        Utils::Migration.new.run
      end
    end
  end
end
