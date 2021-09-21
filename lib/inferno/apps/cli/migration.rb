require_relative '../../utils/migration'

module Inferno
  module CLI
    class Migration
      def run
        Inferno::Application.start(:logging)
        Inferno::Application['logger'].level = Logger::DEBUG

        Utils::Migration.new.run
      end
    end
  end
end
