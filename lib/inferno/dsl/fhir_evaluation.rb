require 'dotenv'
require 'faraday'
require 'fhir_models'
require 'thor'
require 'erb'
require 'yaml'
require 'pathname'

require_relative 'fhir_evaluator/config'
require_relative 'fhir_evaluator/evaluator'
require_relative 'fhir_evaluator/ig'
require_relative 'fhir_evaluator/rule'
require_relative 'fhir_evaluator/evaluation_context'
require_relative 'fhir_evaluator/evaluation_result'
require_relative 'fhir_evaluator/data_summary'
require_relative 'fhir_evaluator/dataset'

module Inferno
  module DSL
    module FHIREvaluation
      class Evaluator
        def initialize(ig_path, data_path)
          Dotenv.load
          Dir.glob(File.join(__dir__, 'fhir_evaluator', 'rules', '*.rb')).each do |file|
            require_relative file
          end

          # To-Do: these paths will be permanently resolved after
          # the evaluator is fully integrated with Inferno.
          validate_args(ig_path, data_path)

          ig = FhirEvaluator::IG.new(File.join(__dir__, 'fhir_evaluator', 'ig', ig_path))

          if data_path
            DatasetLoader.from_path(File.join(__dir__, 'fhir_evaluator', data_path))
          else
            ig.examples
          end

          # Rule execution and result output will be later integrated at phase 2 and 3.

          # results = FhirEvaluator::Evaluator.new(ig).evaluate(data, Config.new)

          # output_results(results, options[:output])
        end

        def validate_args(ig_path, data_path)
          raise 'A path to an IG is required!' unless ig_path

          return unless data_path && (!File.directory? data_path)

          raise "Provided path '#{data_path}' is not a directory"
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
end
