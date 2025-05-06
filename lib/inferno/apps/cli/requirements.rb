require_relative 'requirements_exporter'

module Inferno
  module CLI
    class Requirements < Thor
      desc 'export_csv', 'Export a csv represantation of requirements from an excel file'
      long_desc <<~LONGDESC
        Creates CSV files for tested requirements and requirements which are not
        planned to be tested based on the excel files located in
        "lib/test_kit_name/requirements"
      LONGDESC
      def export_csv
        ENV['NO_DB'] = 'true'
        RequirementsExporter.new.run
      end
    end
  end
end
