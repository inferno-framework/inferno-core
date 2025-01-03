require 'fhir_models'

module Inferno
  module DSL
    class PrimitiveType < FHIR::Element
      attr_accessor :value
    end
  end
end
