require 'pastel'
require_relative 'abstract_outputter'

module Inferno
  module CLI
    class Execute
      # @private
      class ConsoleOutputter  < AbstractOutputter

        COLOR = Pastel.new
        CHECKMARK = "\u2713".freeze
        BAR = ('=' * 80).freeze

        attr_accessor :verbose

        def print_start_message(options)
          self.verbose = options[:verbose]

          puts ''
          puts BAR
          puts "Testing #{options[:suite] || options[:group] || options[:test]}"
          puts BAR
        end

        def print_around_run(options, &block)
          puts "Running tests. This may take a while..."
          # TODO: spinner/progress bar
          yield
        end

        def print_results(options, results)
          verbose_print_json_results

          puts BAR
          puts 'Test Results:'
          puts BAR
          results.each do |result|
            print format_tag(result), ': ', format_result(result), "\n"
            verbose_puts "\tsummary: ",   result.result_message
            verbose_puts "\tmessages: ",  format_messages(result)
            verbose_puts "\trequests: ",  format_requests(result)
            verbose_puts "\tinputs: ",    format_inputs(result)
            verbose_puts "\toutputs: ",   format_outputs(result)
          end
          puts BAR
        end

        def print_end_message(options)
        end

        def print_error(exception)
          puts COLOR.red "Error: #{exception.full_message}"
          verbose_print(exception.backtrace.join('\n'))
        end

        private

        def verbose_print(*args)
          print(COLOR.dim(*args)) if self.verbose
        end

        def verbose_puts(*args)
          args.push("\n")
          verbose_print(*args)
        end

        def format_tag(result)
          if result.runnable.respond_to?(:short_id)
            "#{result.runnable.short_id} #{format_tag_suffix(result)}"
          else
            format_tag_suffix(result)
          end
        end

        def format_tag_suffix(result)
          result.runnable.short_title.presence || result.runnable.title.presence || result.runnable.id
        end

        def format_messages(result)
          result.messages.map do |message|
            "\n\t\t#{message.type}: #{message.message}"
          end.join
        end

        def format_requests(result)
          result.requests.map do |req_res|
            "\n\t\t#{req_res.status} #{req_res.verb.upcase} #{req_res.url}"
          end.join
        end

        def format_session_data(result, attr)
          json = result.send(attr)
          return '' if json.nil?

          JSON.parse(json).map do |hash|
            "\n\t\t#{hash['name']}: #{hash['value']}"
          end.join
        end

        def format_inputs(result)
          format_session_data(result, :input_json)
        end

        def format_outputs(result)
          format_session_data(result, :output_json)
        end

        def format_result(result) # rubocop:disable Metrics/CyclomaticComplexity
          case result.result
          when 'pass'
            COLOR.bold.green(CHECKMARK, ' pass')
          when 'fail'
            COLOR.bold.red 'X fail'
          when 'skip'
            COLOR.yellow '* skip'
          when 'omit'
            COLOR.blue '* omit'
          when 'error'
            COLOR.magenta 'X error'
          when 'wait'
            COLOR.bold '. wait'
          when 'cancel'
            COLOR.red 'X cancel'
          when 'running'
            COLOR.bold '- running'
          else
            raise StandardError.new, "Unrecognized result #{result.result}"
          end
        end

        def verbose_print_json_results(results)
          verbose_puts BAR
          verbose_puts 'JSON Test Results:'
          verbose_puts BAR
          verbose_puts serialize(results)
          verbose_puts BAR
        end
      end
    end
  end
end
