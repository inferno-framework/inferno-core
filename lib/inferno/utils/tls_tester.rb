require 'net/http'
require 'openssl'

module Inferno
	module Utils
		class TlsTester
			# Initialize an instance of the TlsTester class.
			#
			# @param params [Hash] This hash must include either a :uri value or both 
			# 	a :host and :port values. 
			# @return An instance of the TlsTester class with instance variables set.
			def initialize(params)
				if params[:uri].nil?
					if !!(params[:host] && params[:port])
						@host = params[:host]
						@port = params[:port]
					else
						raise ArgumentError, '"uri" or "host"/"port" required by TlsTester'
					end
				else
					@uri = URI(params[:uri])
					@host = @uri.host
					@port = @uri.port
				end
			end

			# Verify that the endpoint set during initialization either conforms to or 
			# fails to meet the input security protocol. 
			#
			# @param action [String (optional) => 'deny'] Determines whether the endpoint is 
			#		evaluated for conformity or nonconformity to the input protocol.
			#		By default, conformance is verified and function calls that aim to verify 
			# 	conformance do not need to include an :action argument. To verify 
			#		nonconformance, the string 'deny' must be included as the :action argument.
			# 	evaluates 
			# @param sslversion [OpenSSL::SSL::Protocol_Version] The security protocol
			#		that is being verified against.  
			# @param readable_version [String] String representation of the sslversion.
			# @return True or False [Boolean] Indicates whether the endpoint conforms or 
			# 	is nonconformant to the protocol - with respect to the intended action 
			#		argument. Eg: action 'deny' will return true when the endpoint denies
			# 	connection, and return false if the connection is initiated without error.
			def verify_protocol(action = 'verify', ssl_version, readable_version)
				http = Net::HTTP.new(@host, @port)
				http.use_ssl = true
				http.min_version = ssl_version
				http.max_version = ssl_version
				http.verify_mode = OpenSSL::SSL::VERIFY_PEER
				begin
					http.request_get(@uri)
				rescue StandardError => e
					return true, "Correctly denied connection error of type #{e.class}, message is #{e.message}" if action == 'deny'
					return false, "Caught TLS Error: #{e.message}", %(
						The following error was returned when the application attempted to connect to the server:

						#{e.message}

						The following parameters were used:

						```
						host: #{@host}
						port: #{@port}
						ssl version: #{ssl_version}
						PEER verify mode
						```
					)
				end
				return [false, "Must deny access to clients requesting #{readable_version}"] if action == 'deny'
				return [true, "Allowed Connection with #{readable_version}"]
			end
		end
	end
end