require_relative './result_collection'
module Inferno
  # @private
  # This class takes an array of results and determines the overall result. This
  # is used to determine the result of a TestGroup/TestSuite based on the
  # results of it's children.
  # It supports custom result logic by accepting a block during initialization.
  # This allows test authors to define custom passing criteria for test groups and suites.
  class ResultSummarizer
    attr_reader :results, :custom_result_block

    def initialize(results, &block)
      @results = results.is_a?(ResultCollection) ? results : ResultCollection.new(results)
      @custom_result_block = block if block_given?
    end

    def summarize
      return 'pass' if custom_results_passing_criteria_met? || optional_results_passing_criteria_met?

      prioritized_result_strings.find { |result_string| unique_result_strings.include? result_string }
    end

    private

    def prioritized_result_strings
      Entities::Result::RESULT_OPTIONS
    end

    def custom_results_passing_criteria_met?
      custom_result_block&.call(results) || false
    end

    def optional_results_passing_criteria_met?
      custom_result_block.nil? && all_optional_results? && unique_result_strings.any?('pass') &&
        unique_result_strings.none? { |result| %w[wait running].include? result }
    end

    def all_optional_results?
      results.required_results.blank?
    end

    def results_for_summary
      custom_result_block || all_optional_results? ? results : results.required_results
    end

    def unique_result_strings
      @unique_result_strings ||= results_for_summary.map(&:result).uniq
    end
  end
end
