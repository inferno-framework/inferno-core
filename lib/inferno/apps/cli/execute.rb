module Inferno
  module CLI
    class Execute
      # TODO use Thor Groups? TTY-Markdown + colorize?
      def run(options)
        if options[:docker_compose]
          rebuilt_options = options
                              .merge({docker_compose: false})
                              .transform_values{|value| value.is_a?(Hash) ? value.to_a.map{|arr| arr.join(':')} : value}
                              .transform_values{|value| value.is_a?(Array) ? value.join(' ') : value}
                              .to_a
                              .join('=')
          `docker compose run inferno bundle exec inferno execute #{rebuilt_options}`
        else
          puts "TODO: heavy lifting here"
        end
      end
    end
  end
end
