module Inferno
  module Utils
    class SuiteTracker
      class << self
        def classes_defined_at_path
          @classes_defined_at_path ||= Hash.new { |hash, key| hash[key] = Set.new }
        end
      end
    end
  end
end
