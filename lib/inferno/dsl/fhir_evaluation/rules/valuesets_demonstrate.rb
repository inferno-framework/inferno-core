# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'
require 'base64'

module Inferno
  module DSL
    module FHIREvaluation
      module Rules
        # This rule evaluates if an IG defines a new valueset, the examples should
        # demonstrate reasonable coverage of that valueset.
        # Note this probably only makes sense for small valuesets
        # such as status options, not something like disease codes from SNOMED.

        # Algorithm:
        # 1. Extract pairs of system and code from include in value sets in IG
        # 2. If valueSet exists in include, retrieve the value sets from UMLS.
        #    Extract pairs of system and code from the result.
        # 3. For each pair of system and code, check if any resources in the IG have instance of them.
        # 4. Count total number of existences.

        class ValueSetsDemonstrate < Rule
          attr_accessor :config, :value_set_unevaluated, :value_set_used, :value_set_unused

          def check(context)
            @config = context.config

            @value_set_unevaluated = []
            @value_set_used = []
            @value_set_unused = []

            collect_valuesets_used(context)

            context.add_result create_result_message()
          end

          def collect_valuesets_used(context)
            context.ig.resources_by_type['ValueSet'].each do |valueset|
              valueset_used_count = 0
              system_codes = extract_systems_codes_from_valueset(valueset)

              value_set_unevaluated << valueset.url if system_codes.none?

              next if value_set_unevaluated.include?(valueset.url)

              resource_used = []

              context.data.each do |resource|
                system_codes.each do |system_code|
                  if !system_code.nil? && find_valueset_used(resource.to_hash, system_code[:system], system_code[:code])
                    valueset_used_count += 1
                    resource_used << resource.id unless resource_used.include?(resource.id)
                  end
                end
              end

              if valueset_used_count.positive?
                value_set_used << "#{valueset.url} is used #{valueset_used_count} times in #{resource_used.count} resources"
              else
                value_set_unused << valueset.url
              end
            end

            value_set_unevaluated.uniq!
          end

          def create_result_message()
            if value_set_unused.none?
              message = 'All Value sets are used in Examples:'
              value_set_used.map { |value_set| message += "\n\t#{value_set}" }

              if value_set_unevaluated.any?
                message += "\nThe following Value Sets were not able to be evaluated: "
                value_set_unevaluated.map { |value_set| message += "\n\t#{value_set}" }
              end

              EvaluationResult.new(message, severity: 'success', rule: self)
            else
              message = 'Value sets with all codes used at least once in Examples:'
              value_set_used.map { |url| message += "\n\t#{url}" }

              message += "\nFound unused Value Sets: "
              value_set_unused.map { |url| message += "\n\t#{url}" }

              if value_set_unevaluated.any?
                message += "\nFound unevaluated Value Sets: "
                value_set_unevaluated.map { |url| message += "\n\t#{url}" }
              end

              EvaluationResult.new(message, rule: self)
            end

          end

          def extract_systems_codes_from_valueset(valueset)
            system_codes = []

            if valueset.to_hash['compose']
              valueset.to_hash['compose']['include'].each do |include|
                if include['valueSet']
                  include['valueSet'].each do |url|
                    retrieve_valueset_api(url)&.each { |system_code| system_codes << system_code }
                  end
                  next
                end

                system_url = include['system']

                if system_url && include['concept']
                  include['concept'].each do |code|
                    system_codes << { system: system_url, code: code.to_hash['code'] }
                  end
                  next
                end

                if system_url
                  if system_url['http://hl7.org/fhir']
                    retrieve_valueset_api(system_url)&.each { |vs| system_codes << vs }
                  end
                  next
                end

                value_set_unevaluated << valueset.url unless system_url

                # Exclude if system is provided as Uniform Resource Name "urn:"
                # Exclude filter
                # Exclude only system is provided (e.g. http://loing.org)
                exclusions = config.data['Rule']['ValueSetsDemonstrate']['Exclude']
                if (exclusions['URL'] && (system_url['urn'])) \
                  || (exclusions['Filter'] && (system_url && include['filter'])) \
                  || (exclusions['SystemOnly'] && (system_url && !include['concept'] && !include['filter']))
                  value_set_unevaluated << valueset.url
                end

              end
            else
              value_set_unevaluated << valueset.url
            end
            system_codes.flatten.uniq
          end

          def find_valueset_used(resource, system, code)
            resource.each do |key, value|
              next unless key == 'code' || ['value', 'valueCodeableConcept', 'valueString',
                                            'valueQuantity', 'valueBoolean',
                                            'valueInteger', 'valueRange', 'valueRatio',
                                            'valueSampleData', 'valueDateTime',
                                            'valuePeriod', 'valueTime'].include?(key)
              next unless value.is_a?(Hash)

              value['coding']&.each do |codeset|
                return true if codeset.to_hash['system'] == system && codeset.to_hash['code'] == code
              end
            end

            false
          end

          def extract_valueset(response)
            value_set = JSON.parse(response.body)

            if value_set['compose'] && value_set['compose']['include']
              value_set['compose']['include'].map do |include|
                include['concept']&.map { |concept| { system: include['system'], code: concept['code'] } }
              end.flatten
            else
              puts 'No Value Set found in the response.'
            end
          end

          def retrieve_valueset_api(url)
            url['http:'] = 'https:' if url['http:']
            uri = URI.parse(url)

            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = (uri.scheme == 'https')

            request = Net::HTTP::Get.new(uri.request_uri)

            username = config.data['Environment']['VSAC']['Url']
            password = config.data['Environment']['VSAC']['Apikey']
            encoded_credentials = Base64.strict_encode64("#{username}:#{password}")
            request['Authorization'] = "Basic #{encoded_credentials}"

            response = http.request(request)

            content_type = response['content-type']
            return unless content_type && !content_type.include?('text/html')

            while response.is_a?(Net::HTTPRedirection)
              redirect_url = response['location']

              redirect_url['xml'] = 'json'
              uri = URI.parse(redirect_url)

              http = Net::HTTP.new(uri.host, uri.port)
              http.use_ssl = (uri.scheme == 'https')

              response = http.request(Net::HTTP::Get.new(uri.request_uri))
            end

            if response.code.to_i == 200
              extract_valueset(response)
            else
              puts "Failed to retrieve the Value Set: #{url}. HTTP Status Code: #{response.code}"
            end
          end
        end
      end
    end
  end
end
