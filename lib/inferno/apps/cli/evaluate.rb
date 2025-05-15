require_relative '../../dsl/fhir_evaluation/evaluator'
require_relative '../../dsl/fhir_evaluation/config'
require_relative '../../entities'
require_relative '../../utils/ig_downloader'
require_relative 'migration'

require 'fileutils'
require 'tempfile'

module Inferno
  module CLI
    class Evaluate
      # @see Inferno::CLI::Main#evaluate
      def run(ig_path, data_path, options)
        tmpdir = Dir.mktmpdir
        Dir.mkdir("#{tmpdir}/data")
        Dir.mkdir("#{tmpdir}/data/igs")
        Dir.mkdir("#{tmpdir}/config")
        FileUtils.cp(File.expand_path('evaluate/database.yml', __dir__), "#{tmpdir}/config/database.yml")

        ENV['TMPDIR'] = tmpdir
        ENV['FHIRPATH_URL'] = 'http://localhost:6790'
        ENV['FHIR_RESOURCE_VALIDATOR_URL'] = 'http://localhost:3501'

        puts 'Starting Inferno Evaluator Services...'
        system("#{services_base_command} up -d #{services_names}")

        ig_path = absolute_path_with_home_expansion(ig_path)
        data_path = absolute_path_with_home_expansion(data_path) if data_path

        Dir.chdir(tmpdir) do
          Migration.new.run(Logger::FATAL) # Hide migration output for evaluator
          evaluate(ig_path, data_path, options)
        end
      ensure
        system("#{services_base_command} down #{services_names}")
        puts 'Stopped Inferno Evaluator Services'

        FileUtils.remove_entry_secure tmpdir
      end

      def services_base_command
        "docker compose -f #{File.join(__dir__, 'evaluate', 'docker-compose.evaluate.yml')}"
      end

      def services_names
        'hl7_validator_service fhirpath'
      end

      # @private
      def absolute_path_with_home_expansion(path)
        if path.starts_with? '~'
          path.sub('~', Dir.home)
        else
          File.absolute_path(path)
        end
      end

      # @see Inferno::CLI::Main#evaluate
      def evaluate(ig_path, data_path, options)
        # NOTE: repositories is required here rather than at the top of the file because
        # the tree of requires means that this file and its requires get required by every CLI app.
        # Sequel::Model, used in some repositories, fetches the table schema at instantiation.
        # This breaks the `migrate` task by fetching a table before the task runs/creates it.
        require_relative '../../repositories'

        validate_args(ig_path, data_path)
        ig = Inferno::Repositories::IGs.new.find_or_load(ig_path)

        check_ig_version(ig)

        data =
          if data_path
            DatasetLoader.from_path(File.join(__dir__, data_path))
          else
            ig.examples
          end

        validator = setup_validator(ig_path)

        evaluator = Inferno::DSL::FHIREvaluation::Evaluator.new(ig, validator)

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

      def setup_validator(ig_path)
        igs_directory = File.join(Dir.pwd, 'data', 'igs')
        if File.exist?(ig_path) && !File.realpath(ig_path).start_with?(igs_directory)
          destination_file_path = File.join(igs_directory, File.basename(ig_path))
          FileUtils.copy_file(ig_path, destination_file_path, true)
          ig_path = "igs/#{File.basename(ig_path)}"
        end
        Inferno::DSL::FHIRResourceValidation::Validator.new(:default, 'evaluator_cli') do
          igs(ig_path)

          cli_context do
            # For our purposes, code display mismatches should be warnings and not affect profile conformance
            displayWarnings(true)
          end
        end
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
