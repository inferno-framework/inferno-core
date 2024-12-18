require_relative '../../../inferno/dsl/fhir_evaluation/evaluator'
require_relative '../../../inferno/entities'
require_relative '../../utils/ig_downloader'

require 'tempfile'

module Inferno
  module CLI
    class Evaluate < Thor::Group
      include Thor::Actions
      include Inferno::Utils::IgDownloader

      def evaluate(ig_path, data_path, _log_level)
        validate_args(ig_path, data_path)
        _ig = get_ig(ig_path)

        # Rule execution, and result output below will be integrated soon.

        # if data_path
        #   DatasetLoader.from_path(File.join(__dir__, data_path))
        # else
        #   ig.examples
        # end

        # config = Config.new
        # evaluator = Inferno::DSL::FHIREvaluation::Evaluator.new(data, config)

        # results = evaluate()
        # output_results(results, options[:output])
      end

      def validate_args(ig_path, data_path)
        raise 'A path to an IG is required!' unless ig_path

        return unless data_path && (!File.directory? data_path)

        raise "Provided path '#{data_path}' is not a directory"
      end

      def get_ig(ig_path)
        if File.exist?(ig_path)
          ig = Inferno::Entities::IG.from_file(ig_path)
        elsif in_user_package_cache?(ig_path.sub('@', '#'))
          # NPM syntax for a package identifier is id@version (eg, hl7.fhir.us.core@3.1.1)
          # but in the cache the separator is # (hl7.fhir.us.core#3.1.1)
          cache_directory = File.join(user_package_cache, ig_path.sub('@', '#'))
          ig = Inferno::Entities::IG.from_file(cache_directory)
        else
          Tempfile.create('package.tgz') do |temp_file|
            load_ig(ig_path, nil, { force: true }, temp_file.path)
            ig = Inferno::Entities::IG.from_file(temp_file.path)
          end
        end
        ig.add_self_to_repository
        ig
      end

      def user_package_cache
        File.join(Dir.home, '.fhir', 'packages')
      end

      def in_user_package_cache?(ig_identifier)
        File.directory?(File.join(user_package_cache, ig_identifier))
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
