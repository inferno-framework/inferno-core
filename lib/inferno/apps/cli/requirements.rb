require_relative 'requirements_exporter'

module Inferno
  module CLI
    class Requirements < Thor
      desc 'export_csv', 'Export a csv represantation of requirements from an excel file'
      long_desc <<~LONGDESC
        TODO
        Generates a template for creating an input preset for a Test Suite.

        With -f option, the preset template is written to the specified
        filename.
      LONGDESC
      # option :filename, banner: '<filename>', aliases: [:f]
      def export_csv
        ENV['NO_DB'] = 'true'
        RequirementsExporter.new.run
      end
    end
  end
end
