module Inferno
  module CLI
    class Evaluator
      def run(_log_level = Logger::DEBUG)
        require_relative '../../../inferno/dsl/fhir_evaluation'

        Inferno::DSL::FHIREvaluation::Evaluator.new
      end
    end
  end
end
