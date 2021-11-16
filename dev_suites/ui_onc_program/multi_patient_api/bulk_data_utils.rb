module BulkDataUtils
	def self.included(klass)
	end 

	def check_capability_statement
		fhir_get_capability_statement(client: :bulk_server)
		assert_response_status([200, 201]) && assert_valid_json(request.response_body)

		capability_statement = JSON.parse(request.response_body) 
		capability_statement['rest'].each do |rest|
			groups = rest['resource'].select { |resource| resource['type'] == 'Group' && resource.key?('operation') }

			for group in groups
				# This flatten was necessary for the smarthealth.it server - is that a mistake on their end, or is it worth taking into consideration
				# the 'definition=>{reference=>http://hl7.org/fhir/uv/bulkdata/OperationDefinition/group-export}' case?
				return if group['operation'].any? do |op|
					if op['definition'].is_a? String 
						op['definition'] == 'http://hl7.org/fhir/uv/bulkdata/OperationDefinition/group-export'
					else 
						op['definition'].flatten.include?('http://hl7.org/fhir/uv/bulkdata/OperationDefinition/group-export')
					end
				end
			end 
		end
		assert false, 'Server CapabilityStatement did not declare support for export operation in Group resource.'
	end 
 
	def export_kick_off(use_token = true)
		headers = { accept: 'application/fhir+json', prefer: 'respond-async'} 
		headers.merge!({authorization: "Bearer #{bulk_access_token}" }) if use_token 

		id = (defined?(groupId) ? groupId : 'example')
		get("Group/#{id}/$export", client: :bulk_server, name: :export, headers: headers)
	end

	def check_export_status(timeout)

		wait_time = 1
		start = Time.now

		begin
			get(client: :polling_location, name: :status_check, headers: { authorization: "Bearer #{bulk_access_token}"})

			retry_after = (response[:headers].find { |header| header.name == 'retry-after' })
			retry_after_val = retry_after.nil? || retry_after.value.nil? ? 0 : retry_after.value.to_i
			wait_time = retry_after_val.positive? ? retry_after_val : wait_time *= 2

			timeout -= Time.now - start + wait_time
			sleep wait_time

		end while response[:status] == 202 and timeout > 0

	end 

	def get_file(file, use_token = true)

		headers = { accept: 'application/fhir+ndjson' }
		headers.merge!({ authorization: "Bearer #{bulk_access_token}" }) if use_token

	 	get(client: :bulk_file_endpoint, headers: headers)

	end 
end 