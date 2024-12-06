# frozen_string_literal: true

require 'dotenv'
require 'faraday'
require 'fhir_models'
require 'thor'
require 'erb'
require 'yaml'
require 'pathname'

require_relative 'config'
require_relative 'rule'
require_relative 'evaluation_context'
require_relative 'evaluation_result'
require_relative 'dataset_loader'

module Inferno
  module DSL
    module FHIREvaluation
      class Evaluator
        def initialize(ig_path, data_path)
          validate_args(ig_path, data_path)

          Dir.glob(File.join(__dir__, 'rules', '*.rb')).each do |file|
            require_relative file
          end

          # IG Import, rule execution, and result output below will be integrated at phase 2 and 3.

          # @ig = File.join(__dir__, 'ig', ig_path)

          # if data_path
          #   DatasetLoader.from_path(File.join(__dir__, data_path))
          # else
          #   ig.examples
          # end

          # results = evaluate(data, Config.new)
          # output_results(results, options[:output])
        end

        def evaluate(data, config = Config.new)
          context = EvaluationContext.new(@ig, data, config)

          active_rules = []
          config.data['Rule'].each do |rulename, rule_details|
            active_rules << rulename if rule_details['Enabled']
          end

          Rule.descendants.each do |rule|
            rule.new.check(context) if active_rules.include?(rule.name.demodulize)
          end

          context.results
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
