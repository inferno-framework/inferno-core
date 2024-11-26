require_relative '../../../inferno/dsl/fhir_evaluation'

module Inferno
  module CLI
    class Evaluator
      def run(_log_level = Logger::DEBUG, ig_path, data_path)
        Inferno::DSL::FHIREvaluation::Evaluator.new(ig_path, data_path)
      end
    end
  end
end
