require 'thor'
require 'erb'
require 'yaml'
require 'pathname'

module FhirEvaluator
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    desc 'evaluate IG_PATH [EXAMPLES_PATH]', 'evaluate the examples for the IG'
    option :output, type: :string
    def evaluate(ig_path, examples_path = nil, config_file = nil)
      config = Config.new(config_file)

      validate_args(ig_path, examples_path)

      ig = FhirEvaluator::IG.new(ig_path)

      data = if examples_path
               Dataset.from_path(examples_path)
             else
               ig.examples
             end

      print(data_summary.to_json, 'Data Summary')

      results = FhirEvaluator::Evaluator.new(ig).evaluate(data, config)

      output_results(results, options[:output])
    end

    no_commands do
      def validate_args(ig_path, examples_path)
        raise 'A path to an IG is required!' unless ig_path

        raise "Provided path '#{examples_path}' is not a directory" if examples_path && (!File.directory? examples_path)
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
