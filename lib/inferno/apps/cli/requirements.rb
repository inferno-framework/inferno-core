require_relative 'requirements_coverage_checker'
require_relative 'requirements_exporter'

module Inferno
  module CLI
    class Requirements < Thor
      desc 'export_csv', 'Export a CSV represantation of requirements from an excel file'
      long_desc <<~LONGDESC
        Creates CSV files for tested requirements and requirements which are not
        planned to be tested based on the excel files located in
        "lib/test_kit_name/requirements"
      LONGDESC
      def export_csv
        ENV['NO_DB'] = 'true'
        RequirementsExporter.new.run
      end

      desc 'check', 'Check whether the current requirements CSV files are up to date'
      long_desc <<~LONGDESC
        Check whether the requirements CSV files are up to date with the excel
        files in "lib/test_kit_name/requirements"
      LONGDESC
      def check
        ENV['NO_DB'] = 'true'
        RequirementsExporter.new.run_check
      end

      desc 'coverage [TEST_SUITE_ID]',
           "Check whether all of a test suite's requirements are tested. If no test suite id is provided, " \
           'all test suites in the current test kit will be checked.'
      long_desc <<~LONGDESC
        Check whether all of the requirements declared by a test suite are
        tested by the tests in the test suite
      LONGDESC
      def coverage(test_suite_id = nil)
        ENV['NO_DB'] = 'true'

        require_relative '../../../inferno'

        Inferno::Application.start(:requirements)

        if test_suite_id.present?
          RequirementsCoverageChecker.new(test_suite_id).run
        else
          Inferno::Repositories::TestSuites.all.each do |test_suite|
            if Object.const_source_location(test_suite.to_s).first.start_with? Dir.pwd
              RequirementsCoverageChecker.new(test_suite.id).run
            end
          end
        end
      end

      desc 'check_coverage [TEST_SUITE_ID]',
           'Check whether the coverage CSV files are up to date'
      long_desc <<~LONGDESC
        Check whether the coverage CSV files are up to date
      LONGDESC
      def check_coverage(test_suite_id = nil)
        ENV['NO_DB'] = 'true'

        require_relative '../../../inferno'

        Inferno::Application.start(:requirements)

        if test_suite_id.present?
          RequirementsCoverageChecker.new(test_suite_id).run_check
        else
          Inferno::Repositories::TestSuites.all.each do |test_suite|
            if Object.const_source_location(test_suite.to_s).first.start_with? Dir.pwd
              RequirementsCoverageChecker.new(test_suite.id).run_check
            end
          end
        end
      end
    end
  end
end
