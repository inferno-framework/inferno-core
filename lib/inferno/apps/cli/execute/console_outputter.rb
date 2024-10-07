require 'pastel'
require_relative '../../web/serializers/test_run'
require_relative '../../web/serializers/result'

module Inferno
  module CLI
    class Execute
      # @private
      class ConsoleOutputter
        CHECKMARK = "\u2713".freeze
        BAR = ('=' * 80).freeze

        def print_start_message(options)
          puts ''
          puts BAR
          puts "Testing #{options[:suite] || options[:group] || options[:test]}"
          puts BAR
        end

        def print_around_run(_options)
          puts 'Running tests. This may take a while...'
          # TODO: spinner/progress bar
          yield
        end

        def print_results(options, results)
          verbose_print_json_results(options, results)

          puts BAR
          puts 'Test Results:'
          puts BAR
          results.each do |result|
            print format_tag(result), ': ', format_result(result), "\n"
            verbose_puts(options, "\tsummary: ",     result.result_message)
            verbose_puts(options, "\tmessages: ",    format_messages(result))
            verbose_puts(options, "\trequests: ",    format_requests(result))
            verbose_puts(options, "\tinputs: ",      format_inputs(result))
            verbose_puts(options, "\toutputs: ",     format_outputs(result))
          end
          puts BAR
        end

        def print_end_message(options); end

        def print_error(options, exception)
          puts color.red "Error: #{exception.full_message}"
          verbose_print(options, exception.backtrace&.join('\n'))
        end

        # private

        def verbose_print(options, *args)
          print(color.dim(*args)) if options[:verbose]
        end

        def color
          @color ||= Pastel.new(enabled: $stdout.tty?)
        end

        def verbose_puts(options, *args)
          args.push("\n")
          verbose_print(options, *args)
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
            color.bold.green(CHECKMARK, ' pass')
          when 'fail'
            color.bold.red 'X fail'
          when 'skip'
            color.yellow '* skip'
          when 'omit'
            color.blue '* omit'
          when 'error'
            color.magenta 'X error'
          when 'wait'
            color.bold '. wait'
          when 'cancel'
            color.red 'X cancel'
          when 'running'
            color.bold '- running'
          else
            raise StandardError.new, "Unrecognized result #{result.result}"
          end
        end

        def verbose_print_json_results(options, results)
          verbose_puts(options, BAR)
          verbose_puts(options, 'JSON Test Results:')
          verbose_puts(options, BAR)
          verbose_puts(options, serialize(results))
          verbose_puts(options, BAR)
        end

        def serialize(entity)
          case entity.class.to_s
          when 'Array'
            JSON.pretty_generate(entity.map { |item| JSON.parse serialize(item) })
          when lambda { |x|
                 defined?(x.constantize) && defined?("Inferno::Web::Serializers::#{x.split('::').last}".constantize)
               }
            "Inferno::Web::Serializers::#{entity.class.to_s.split('::').last}".constantize.render(entity)
          else
            raise StandardError, "CLI does not know how to serialize #{entity.class}"
          end
        end
      end
    end
  end
end
