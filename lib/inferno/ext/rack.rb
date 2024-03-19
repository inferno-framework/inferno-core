module Rack
  class Request
    def headers
      @headers ||= Headers.new(@env)
    end

    class Headers
      def initialize(env)
        @env = env
      end

      def [](k)
        @env[header_to_env_key(k)]
      end

      def []=(k, v)
        @env[header_to_env_key(k)] = v
      end

      def add(k, v)
        k = header_to_env_key(k)
        case existing = @env[k]
        when nil
          @env[k] = v
        when String
          @env[k] = [existing, v]
        when Array
          existing << v
        end
      end

      def delete(k)
        @env.delete(header_to_env_key(k))
      end

      def each
        return to_enum(:each) unless block_given?

        @env.each do |k, v|
          next unless k = env_to_header_key(k)
          yield k, v
        end
      end

      def fetch(k, &block)
        @env.fetch(header_to_env_key(k), &block)
      end

      def has_key?(k)
        @env.has_key?(header_to_env_key(k))
      end

      def to_h
        h = {}
        each{|k, v| h[k] = v}
        h
      end

      private

      def env_to_header_key(k)
        case k
        when /\AHTTP_/
          k = k[5..-1]
          k.downcase!
          k.tr!('_', '-')
          k
        when "CONTENT_LENGTH", "CONTENT_TYPE"
          k = k.downcase
          k.tr!('_', '-')
          k
        end
      end

      def header_to_env_key(k)
        k = k.upcase
        k.tr!('-', '_')
        unless k == "CONTENT_LENGTH" || k == "CONTENT_TYPE"
          k = "HTTP_#{k}"
        end
        k
      end
    end
  end
end
