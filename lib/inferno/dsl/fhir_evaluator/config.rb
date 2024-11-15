module FhirEvaluator
  class Config
    EVALUATOR_HOME = File.realpath(File.join(File.dirname(__FILE__), '..', '..'))
    DEFAULT_FILE = File.join(EVALUATOR_HOME, 'config', 'default.yml')
    attr_accessor :data

    # def initialize(config_file = nil)
    #   @data = if config_file.nil?
    #             YAML.load_file(File.absolute_path(DEFAULT_FILE))
    #           else
    #             YAML.load_file(File.absolute_path(config_file))
    #           end

    #   raise(TypeError, 'Malformed configuration') unless @data.is_a?(Hash)

    #   def method_missing(name, *args, &)
    #     section = @data[name.to_s]
    #     if section
    #       Section.new(section)
    #     else
    #       super
    #     end
    #   end

    #   def respond_to_missing?(name, include_private = false)
    #     @data.key?(name.to_s) || super
    #   end
    # end

    class Section
      def initialize(details)
        @details = details
      end

      def method_missing(name, *_args)
        attribute = @details[name.to_s]
        if attribute.is_a?(Hash)
          Section.new(attribute)
        else
          attribute
        end
      end

      def respond_to_missing?(name, include_private = false)
        @details.key?(name.to_s) || super
      end
    end
  end
end
