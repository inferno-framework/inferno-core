module Inferno
  # The ResultCollection class is used to manage a collection of Inferno::Entities::Result objects.
  # It provides methods to filter required and optional results, access results
  # by index or by their runnable IDs, and iterate over the collection.
  #
  # @example
  #
  #   results = [
  #     Result.new(test_group_id: 'group_id1', result: 'pass'),
  #     Result.new(test_group_id: 'group_id2', result: 'fail'),
  #     Result.new(test_group_id: 'group_id3', result: 'pass')
  #   ]
  #
  #   result_collection = Inferno::ResultCollection.new(results)
  #
  #   # Access by index
  #   result = result_collection[0]
  #
  #   # Access by runnable ID (partial)
  #   result = result_collection['group_id2']
  #
  #   # Iterate over results
  #   result_collection.each do |result|
  #     puts result.result
  #   end
  #
  #   # Get required results
  #   required_results = result_collection.required_results
  #
  #   # Get optional results
  #   optional_results = result_collection.optional_results
  # @private
  class ResultCollection
    include Enumerable

    attr_reader :results

    def initialize(results = [])
      @results = results
    end

    def [](key)
      key.is_a?(Integer) ? results[key] : lookup_by_runnable_id(key)
    end

    def <<(result)
      results << result
    end

    def each(&)
      results.each(&)
    end

    def required_results
      results.select(&:required?)
    end

    def optional_results
      results.select(&:optional?)
    end

    private

    def lookup_by_runnable_id(key)
      results.find { |result| result.runnable&.id == key.to_s || result.runnable&.id&.end_with?("-#{key}") }
    end
  end
end
