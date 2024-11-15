# frozen_string_literal: true

module FhirEvaluator
  class Rule
    def check(_context)
      raise 'not implemented'
    end

    # Get the subclasses of this class, ie, the actual implemented Rules.
    def self.descendants
      @descendants ||= []
    end

    def self.inherited(subclass)
      super
      Rule.descendants << subclass
    end
  end
end
