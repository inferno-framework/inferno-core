require_relative '../../../inferno/dsl/fhir_evaluation/evaluator'
require_relative '../../../inferno/dsl/fhir_evaluation/config'
require_relative '../../../inferno/entities'
require_relative '../../utils/ig_downloader'

require 'tempfile'

module Inferno
  module CLI
    class Evaluate < Thor::Group
      def evaluate(ig_path, data_path, _log_level)
        validate_args(ig_path, data_path)
        ig = Inferno::Repositories::IGs.new.find_or_load(ig_path)

        check_ig_version(ig)

        data =
          if data_path
            DatasetLoader.from_path(File.join(__dir__, data_path))
          else
            ig.examples
          end

        evaluator = Inferno::DSL::FHIREvaluation::Evaluator.new(ig)

        config = Inferno::DSL::FHIREvaluation::Config.new
        results = evaluator.evaluate(data, config)
        output_results(results, options[:output])
      end

      def validate_args(ig_path, data_path)
        raise 'A path to an IG is required!' unless ig_path

        return unless data_path && (!File.directory? data_path)

        raise "Provided path '#{data_path}' is not a directory"
      end

      def check_ig_version(ig)
        versions = ig.ig_resource.fhirVersion

        return unless versions.any? { |v| v > '4.0.1' }

        puts '**WARNING** The selected IG targets a FHIR version higher than 4.0.1, which is not supported by Inferno.'
      end

      def output_results(results, output)
        if output&.end_with?('json')
          oo = FhirEvaluator::EvaluationResult.to_operation_outcome(results)
          File.write(output, oo.to_json)
          puts "Results written to #{output}"
        else
          counts = results.group_by(&:severity).transform_values(&:count)
          print(counts, 'Result Count')
          puts "\n"
          puts results
        end
      end

      def print(output_fields, title)
        puts("╔══════════════ #{title} ═══════════════╗")
        puts('║ ╭────────────────┬──────────────────────╮ ║')
        output_fields.each_with_index do |(key, value), i|
          field_name = pad(key, 14)
          field_value = pad(value.to_s, 20)
          puts("║ │ #{field_name} │ #{field_value} │ ║")
          puts('║ ├────────────────┼──────────────────────┤ ║') unless i == output_fields.length - 1
        end
        puts('║ ╰────────────────┴──────────────────────╯ ║')
        puts('╚═══════════════════════════════════════════╝')
      end

      def pad(string, length)
        format("%#{length}.#{length}s", string)
      end
    end
  end
end
