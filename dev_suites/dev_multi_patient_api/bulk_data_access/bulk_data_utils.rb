require 'pry'
module BulkDataUtils

	VERSION = 'R4'
	NON_US_CORE_KLASS = ['Location'].freeze
	MAX_NUM_RECENT_LINES = 100

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

		stream(endpoint, process_body, headers: headers)
		process_chunk_line.call(hanging_chunk)

		# TODO --> Would lijke for this block to get called once during the 
		#					 block above so that we can check what the response is 
		#					 and opt out if its bad or if the headers aren't what we
		#					 need.
		process_response.call(response) 

	end

	def predefined_device_type?(resource)  
		return false if resource.nil?


	end 

	# TODO: Deal with device and lab edge cases
	def determine_profile(resource)

		return unless profile_definitions[0][:profile].nil?

		#return nil if resource.resourceType == 'Device' && !predefined_device_type?(resource)
		#return nil if NON_US_CORE_KLASS.include(resource.resourceType)

		#Inferno::ValidationUtil.guess_profile(resource, @version)
	end 

	def validate(klass, resource, profile)

		# TODO: How do I collect errors? 
		assert resource_is_valid?(resource: resource, profile_url: profile)

	end 

	def walk_element(element, steps)
		return nil if element.nil? 
		return yield(element)	if steps.empty?
			
		step = steps.shift

		return element.find { |elem| !walk_element(elem, steps).nil? } if element.is_a?(Array)
		walk_element(element.send(step.to_sym), steps) if element.respond_to?(step.to_sym)
	end 

	# NOTE: Block will be called regardless of if retrieved is nil. It is up 
	#				up to block writer to account for nil case
	def resolve_element_from_path(element, path)
		steps = path.split('.')
		steps.delete_if { |step| step.empty? }
		retrieved = walk_element(element, steps) { yield if block_given?}
	end 

	# TODO: Implement 
	def find_slice_by_values(element, values)

	end

	def find_slice(resource, path, discriminator)
		resolve_element_from_path(resource, path) do |list|
			case discriminator[:type]
			when 'patternCodeableConcept'
				code_path = [discriminator[:path], 'coding'].join('.')
				resolve_element_from_path(list, code_path) do |coding|
					coding.code == discriminator[:code] && coding.system == discriminator[:system]
				end 
			when 'patternIdentifier'
				resolve_element_from_path(list, discriminator[:path]) do |identifier|
					identifier.system == discriminator[:system]
				end 
			when 'value'
				values_clone = discriminator[:values].deep_dup
				values_clone.each { |value| value[:path] = value[:path].split('.') }
				find_slice_by_values(list, values_clone)
			when 'type'
				case discriminator[:code]
				when 'Date'
					begin
					rescue
					end 
				when 'String'
					list.is_a? String
				else
					list.is_a? FHIR.const_get(discriminator[:code])
				end 
			end 
		end
	end 

	def process_must_support(must_support_info, resource)
		must_support_info[:elements].reject! do |ms_elem|
			resolve_element_from_path(resource, ms_elem[:path]) do |value|
				value.to_hash.reject! { |key, _| key == 'extension' } if value.respond_to?(:to_hash)
				(value.present? || !value) && (ms_elem[:fixed_value].nil? || value == ms_elem[:fixed_value]) 
			end 
		end 

		must_support_info[:extensions].reject! do |ms_extension|
			resource.extension.any? { |extension| extension.url == ms_extension[:url] }
		end

		must_support_info[:slices].reject! do |ms_slice|
			find_slice(resource, ms_slice[:path], ms_slice[:discriminator])
		end
	end 

	def pull_invalid_bindings(binding_def, resource)
	
	end 

	def validate_bindings(bindings, resource)

		bindings.select { |binding_def| binding_def[:strength] == 'required' }.each do |binding_def|
			begin
				bad_bindings = pull_invalid_bindings(binding_def, resource)
			rescue
				break
			end 
		end 

	end 

	def process_profile_definitions(profile_definitions, profile_url, resource)

		binding.pry
		profile_definition = profile_definitions.find { |prof_def| prof_def[:profile] == profile_url }
		process_must_support(profile_definition[:must_support_info], resource)
		validate_bindings(profile_definition[:binding_info], resource)
		
	end 

	# Use stream_ndjson to keep pulling chunks off the response body as they come in
	# lots of unclear if statements based off lines to validate --> investigate this
		#
	# For each chunk read in, get the resource and record the id of whether it is a patient 
	#	
	def check_file_request(file, 
												 klass, 
												 validate_all, 
												 lines_to_validate, 
												 profile_definitions)

		patient_ids_seen = [] # TODO: Explore --> any reason to make this global?
		line_collection = []
		line_count = 0

		headers = { accept: 'application/fhir+ndjson' }
		headers.merge!( { authorization: "Bearer #{bulk_access_token}" } ) if requires_access_token

		process_line = proc { |resource|

			break unless validate_all || line_count < lines_to_validate # TOFIX || klass == 'Patient' && @patient_ids_seen.length < MIN_RESOURCE_COUNT

			next if resource.nil? || resource.strip.empty? 

			line_collection << resource unless line_count < MAX_NUM_RECENT_LINES
			line_count += 1
			
			resource = FHIR.from_contents(resource)
			resource_type = resource.class.name.demodulize
			assert resource_type == klass, "Resource type \"#{resource_type}\" at line \"#{line_count}\" does not match type defined in output \"#{klass}\")"
			
			patient_ids_seen << resource.id if klass == 'Patient'

			# TODO: Do I need this? I should pull directly from metadata, right? determine_profile(resource, profile_definitions)

			profile_url = profile_definitions[0][:profile]

			validate(klass, resource, profile_url)

			process_profile_definitions(profile_definitions, profile_url, resource)






			# Called on every single line, even though leading lines kinda partitions the input

			#	IMPLEMENT --> break if statement prevents how many lines we need to validate
			
			# Where is this coming from?
			# resource = versioned_resource_class.from_contents(resource)
		  #	resource_type = resource.class.name.demodulize
			# assert resource_type == klass, "Resource type \"#{resource_type}\" at line \"#{line_count}\" does not match type defined in output \"#{klass}\")"
			
			
		}

		process_headers = proc { |headers| 

		}

		stream_ndjson(file['url'], headers, process_line, process_headers)

	end 

	# Determine whether the file items in bulk_status_output contains resources 
	#	that conform to the given profiles. 
	# 
	# @param klass [FHIR ResourceType] 
	# @param profile_definitions []
	# @param lines_to_validate [Integer] must be an integer greater than or equal to 1
	# @param validate_all [Boolean] 
	def output_conforms_to_profile?(klass, 
																	profile_definitions = [], 
																	lines_to_validate = 100,
																	validate_all = false)

		skip 'A non-zero number of lines must be validated'	unless validate_all || lines_to_validate > 0												
		skip 'Output from Bulk Data Server not found' unless bulk_status_output.present?

		assert_valid_json(bulk_status_output)

		file_list = JSON.parse(bulk_status_output).select { |file| file['type'] == klass }

		skip "No #{klass} resource file item returned by server." if file_list.empty?

		success_count = 0
				
		file_list.each do |file|
			success_count += check_file_request(file, klass, validate_all, lines_to_validate, profile_definitions)
		end 

		return !success_count.zero? 
	end 
end 