require_relative 'suite_input_template'

module Inferno
  module CLI
    class Suite < Thor
      desc 'input_template SUITE_ID', 'Create a template for preset inputs'
      long_desc <<~LONGDESC
        Generates a template for creating an input preset for a Test Suite.

        With -f option, the preset template is written to the specified
        filename.
      LONGDESC
      option :filename, banner: '<filename>', aliases: [:f]
      def input_template(suite_id)
        SuiteInputTemplate.new.run(suite_id, options)
      end
    end
  end
end
