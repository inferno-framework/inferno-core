module Inferno
  module DSL
    module FHIREvaluation
      class Config
        DEFAULT_FILE = File.join(__dir__, 'default.yml')
        attr_accessor :data

        # To-do: add config_file as arguments
        def initialize(config_file = nil)
          @data = if config_file.nil?
                    YAML.load_file(File.absolute_path(DEFAULT_FILE))
                  else
                    YAML.load_file(File.absolute_path(config_file))
                  end

          raise(TypeError, 'Malformed configuration') unless @data.is_a?(Hash)
        end
      end
    end
  end
end
