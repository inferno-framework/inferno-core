require_relative '../../utils/preset_template_generator'

module Inferno
  module CLI
    class SuiteInputTemplate
      def run(suite_id, options)
        require_relative '../../../inferno'

        Inferno::Application.start(:suites)

        suite = Inferno::Repositories::TestSuites.new.find(suite_id)
        if suite.nil?
          puts "No Test Suite found with id: #{suite_id}"
          return 1
        end

        output = JSON.pretty_generate(Inferno::Utils::PresetTemplateGenerator.new(suite).generate)

        if options[:filename].present?
          path = File.join(Dir.pwd, 'config', 'presets', options[:filename])
          FileUtils.mkdir_p(File.dirname(path))

          File.open(path, 'w') { |f| f.puts(output) }
        else
          puts output
        end
      end
    end
  end
end
