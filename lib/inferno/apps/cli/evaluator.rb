require_relative '../../../inferno/dsl/fhir_evaluator/evaluator'

module Inferno
  module CLI
    class Evaluator
      def run(ig_path, data_path, _log_level)
        Inferno::DSL::FHIREvaluation::Evaluator.new(ig_path, data_path)
      end
    end
  end
end
