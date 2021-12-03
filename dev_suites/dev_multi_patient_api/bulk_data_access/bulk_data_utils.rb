require 'pry'
module BulkDataUtils

	def self.included(klass)

	end 

	# Locally stored JWK related code i.e. pulling from  bulk_data_jwks.json.
	# Takes an encryption method as a string and filters for the corresponding
	# key. The :bulk_encryption_method symbol was not recognized from within the
	# scope of this method, hence why its passed as a parameter.
	#
	# In program, this information was set within the config.yml file and related
	# methods written within the testing_instance.rb file. The following
	# code cherry picks what was needed from those files, but we should probably
	# make an organizational decision about where this stuff will live.
	def get_bulk_selected_private_key(encryption)
		bulk_data_jwks = JSON.parse(File.read(File.join(File.dirname(__FILE__), 'bulk_data_jwks.json')))
		bulk_private_key_set = bulk_data_jwks['keys'].select { |key| key['key_ops']&.include?('sign') }
		bulk_private_key_set.find { |key| key['alg'] == encryption }
	end

	# TODO: Clean up params
	def create_client_assertion(encryption_method:, iss:, sub:, aud:, exp:, jti:)
		bulk_private_key = get_bulk_selected_private_key(encryption_method)
		jwt_token = JSON::JWT.new(iss: iss, sub: sub, aud: aud, exp: exp, jti: jti).compact
		jwk = JSON::JWK.new(bulk_private_key)

		jwt_token.kid = jwk['kid']
		jwk_private_key = jwk.to_key
		client_assertion = jwt_token.sign(jwk_private_key, bulk_private_key['alg'])
	end 

	def build_authorization_request(encryption_method:,
								scope:,
								iss:,
								sub:,
								aud:,
								content_type: 'application/x-www-form-urlencoded',
								grant_type: 'client_credentials',
								client_assertion_type: 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
								exp: 5.minutes.from_now,
								jti: SecureRandom.hex(32))
		header =
			{
				content_type: content_type,
				accept: 'application/json'
			}.compact

		client_assertion = create_client_assertion(encryption_method: encryption_method, iss: iss, sub: sub, aud: aud, exp: exp, jti: jti)

		query_values =
			{
				'scope' => scope,
				'grant_type' => grant_type,
				'client_assertion_type' => client_assertion_type,
				'client_assertion' => client_assertion.to_s
			}.compact

		uri = Addressable::URI.new
		uri.query_values = query_values

		{ body: uri.query, headers: header }
	end

	def declared_export_support? 
		fhir_get_capability_statement(client: :bulk_server)

		assert_response_status([200, 201])
		assert_valid_json(request.response_body)

		definition = 'http://hl7.org/fhir/uv/bulkdata/OperationDefinition/group-export'
		capability_statement = JSON.parse(request.response_body)
		
		capability_statement['rest'].each do |rest|
			groups = rest['resource'].select { |resource| resource['type'] == 'Group' } 
			return true if groups.any? do |group|
				group.has_key?('operation') && group['operation'].any? do |operation|
					if operation['definition'].is_a? String 
						operation['definition'] == definition
					else
						operation['definition'].flatten.include?(definition)
					end
				end 
			end 
		end 
		return false
	end 
 
	def export_kick_off(use_token = true)
		headers = { accept: 'application/fhir+json', prefer: 'respond-async' } 
		headers.merge!( { authorization: "Bearer #{bulk_access_token}" } ) if use_token 

		# TODO: Do I need to use defined? or can I just check its existence as-is
		id = defined?(group_id) ? group_id : 'example'
		get("Group/#{id}/$export", client: :bulk_server, name: :export, headers: headers)
	end

	def check_export_status(timeout)

		wait_time = 1
		start = Time.now

		begin
			get(client: :polling_location, headers: { authorization: "Bearer #{bulk_access_token}"})

			retry_after = (response[:headers].find { |header| header.name == 'retry-after' })
			retry_after_val = retry_after.nil? || retry_after.value.nil? ? 0 : retry_after.value.to_i
			wait_time = retry_after_val.positive? ? retry_after_val : wait_time *= 2

			timeout -= Time.now - start + wait_time
			sleep wait_time

		end while response[:status] == 202 and timeout > 0

	end 






	## GROUP 3







	def get_file(endpoint, use_token = true)
		headers = { accept: 'application/fhir+ndjson' }
		headers.merge!({ authorization: "Bearer #{bulk_access_token}" }) if use_token

	 	get(endpoint, headers: headers)
	end 

	# Responsibility falls on the process_chunk block to check whether the input
	# line is nil or empty. 
	def stream_ndjson(endpoint, headers, process_chunk_line, process_response)

		hanging_chunk = String.new 

		process_body = proc { |chunk| 
			
			hanging_chunk << chunk 
			chunk_by_lines = hanging_chunk.lines

			hanging_chunk = chunk_by_lines.pop || String.new

			chunk_by_lines.each do |elem| 
				process_chunk_line.call(elem)
			end 
		}	

		stream(endpoint, process_body, headers)
		process_response.call(response) 
		process_chunk_line.call(hanging_chunk)
	end

	def check_file_request(file, klass, to_validate, profile_definitions)

		leading_lines = []
		line_count = 0
		max_lines = 100

		headers = { accept: 'application/fhir+ndjson' }.merge! 
		headers.merge!( { authorization: "Bearer #{bulk_access_token}" } ) unless requires_access_token

		proc { |resource|
			next if resource.nil? || resource.strip.empty? 

			line_count += 1
			leading_lines << resource unless line_count > max_lines

			# Called on every single line, even though leading lines kinda partitions the input

			#	IMPLEMENT --> break if statement prevents how many lines we need to validate
			
			# Where is this coming from?
			# resource = versioned_resource_class.from_contents(resource)
		  #	resource_type = resource.class.name.demodulize
			# assert resource_type == klass, "Resource type \"#{resource_type}\" at line \"#{line_count}\" does not match type defined in output \"#{klass}\")"
			
			
		}

	end 

	# G
	def test_output_against_profile(klass, profile_definitions = [], lines_to_validate = 0)

		# TODO: Make a judgement about whether to include 'lines_to_validate entered as 0' guard statement 
		validate_all = lines_to_validate == 'all' ? true : false 

		file_list = JSON.parse(bulk_status_output).select { |file| file['type'] == 'Patient' }
		skip "No #{klass} resource file item returned by server." if file_list.empty?

		success_count = 0
		
		#file_list = bulk_status_output.select 
		
		# bulk_status_output

		# bulk_status_output should contain the response from the server for
		# status check after export is completed --> basically the output
		# in inferno-program since it has already been parsed 

 
		# Validate all lines
		# Search through all files for the given type

		# All we are really doing is going through each file given in the ouput
		# and validating that file's existence 


	end 
end 