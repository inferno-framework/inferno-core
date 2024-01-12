module Inferno
  # @private
  # This class takes an array of results and determines the overall result. This
  # is used to determine the result of a TestGroup/TestSuite based on the
  # results of it's children.
  class ResultSummarizer
    attr_reader :results

    def initialize(results)
      @results = results
    end

    def summarize
      prioritized_result_strings.find { |result_string| unique_result_strings.include? result_string }
    end

    private

    def prioritized_result_strings
      if all_optional_results?
        Entities::Result::RESULT_OPTIONS.slice(0, 3) + Entities::Result::RESULT_OPTIONS.slice(3, 8).reverse!.rotate!
      else
        Entities::Result::RESULT_OPTIONS
      end
    end

    def required_results
      @required_results ||= results.select(&:required?)
    end

    def all_optional_results?
      required_results.blank?
    end

    def results_for_summary
      all_optional_results? ? results : required_results
    end

    def unique_result_strings
      @unique_result_strings ||=
        results_for_summary.map(&:result).uniq
    end
  end
end
