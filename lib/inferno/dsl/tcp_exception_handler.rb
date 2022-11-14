module Inferno
  module DSL
    # @private
    module TCPExceptionHandler
      def tcp_exception_handler(&block)
        block.call
      rescue Faraday::ConnectionFailed, SocketError => e
        e.message.include?('Failed to open TCP') ? raise(Exceptions::AssertionException, e.message) : raise(e)
      end
    end
  end
end
