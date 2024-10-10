require_relative 'result_collection'
module Inferno
  # @private
  # This class takes an array of results and determines the overall result. This
  # is used to determine the result of a TestGroup/TestSuite based on the
  # results of it's children.
  class ResultSummarizer
    attr_reader :results

    def initialize(results)
      @results = results.is_a?(ResultCollection) ? results : ResultCollection.new(results)
    end

    def summarize
      return 'pass' if optional_results_passing_criteria_met?

      prioritized_result_strings.find { |result_string| unique_result_strings.include? result_string }
    end

    private

    def prioritized_result_strings
      Entities::Result::RESULT_OPTIONS
    end

    def optional_results_passing_criteria_met?
      all_optional_results? && unique_result_strings.any?('pass') &&
        unique_result_strings.none? { |result| %w[wait running].include? result }
    end

    def all_optional_results?
      results.required_results.blank?
    end

    def results_for_summary
      all_optional_results? ? results : results.required_results
    end

    def unique_result_strings
      @unique_result_strings ||= results_for_summary.map(&:result).uniq
    end
  end
end
