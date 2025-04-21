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
            @value_set_used = []
            @value_set_unused = []
            @value_set_unevaluated = []

            classify_valuesets(context)

            context.add_result create_result_message
          end

          # rubocop:disable Metrics/CyclomaticComplexity
          def classify_valuesets(context)
            context.ig.value_sets.each do |valueset|
              valueset_used_count = 0
              system_codes = extract_systems_codes_from_valueset(valueset)

              value_set_unevaluated << "#{valueset.url}: unable to find system and code" if system_codes.none?
              value_set_unevaluated.uniq!

              next if value_set_unevaluated.any? { |element| element.include?(valueset.url) }

              resource_used = []

              context.data.each do |resource|
                system_codes.each do |system_code|
                  next unless !system_code.nil? && resource_uses_code(resource.to_hash, system_code[:system],
                                                                      system_code[:code])

                  valueset_used_count += 1
                  resource_used << resource.id unless resource_used.include?(resource.id)
                end
              end

              if valueset_used_count.positive?
                # rubocop:disable Layout/LineLength
                value_set_used << "#{valueset.url} is used #{valueset_used_count} times in #{resource_used.count} resources"
                # rubocop:enable Layout/LineLength
              else
                value_set_unused << valueset.url
              end
            end
          end
          # rubocop:enable Metrics/CyclomaticComplexity

          # rubocop:disable Metrics/CyclomaticComplexity
          def create_result_message
            if value_set_unused.none?
              message = 'All ValueSets are used in examples:'
              value_set_used.map { |value_set| message += "\n\t#{value_set}" }

              if value_set_unevaluated.any?
                message += "\nThe following Value Sets were not able to be evaluated: "
                value_set_unevaluated.map { |value_set| message += "\n\t#{value_set}" }
              end

              EvaluationResult.new(message, severity: 'success', rule: self)
            else
              message = 'Found ValueSets with all codes used (at least once) in examples:'
              value_set_used.map { |url| message += "\n\t#{url}" }

              message += "\nFound unused ValueSets: "
              value_set_unused.map { |url| message += "\n\t#{url}" }

              if value_set_unevaluated.any?
                message += "\nFound unevaluated ValueSets: "
                value_set_unevaluated.map { |url| message += "\n\t#{url}" }
              end

              EvaluationResult.new(message, rule: self)
            end
          end
          # rubocop:enable Metrics/CyclomaticComplexity

          # rubocop:disable Metrics/CyclomaticComplexity
          def extract_systems_codes_from_valueset(valueset)
            system_codes = []

            if valueset.to_hash['compose']
              valueset.to_hash['compose']['include'].each do |include|
                if include['valueSet']
                  include['valueSet'].each do |url|
                    retrieve_valueset_from_api(url)&.each { |system_code| system_codes << system_code }
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
                    retrieve_valueset_from_api(system_url)&.each { |vs| system_codes << vs }
                  end
                  next
                end

                value_set_unevaluated << "#{valueset.url}: system url not provided" unless system_url

                # Exclude if system is provided as Uniform Resource Name "urn:"
                # Exclude filter
                # Exclude only system is provided (e.g. http://loing.org)
                exclusions = config.data['Rule']['ValueSetsDemonstrate']['Exclude']
                if exclusions['URL'] && (system_url['urn'])
                  value_set_unevaluated << "#{valueset.url}: unable to handle Uniform Resource Name"
                end

                if exclusions['Filter'] && (system_url && include['filter'])
                  value_set_unevaluated << "#{valueset.url}: unable to handle filter"
                end

                if exclusions['SystemOnly'] && (system_url && !include['concept'] && !include['filter'])
                  value_set_unevaluated << "#{valueset.url}: unabe to handle SystemOnly"
                end
              end
            else
              value_set_unevaluated << valueset.url
            end
            system_codes.flatten.uniq
          end
          # rubocop:enable Metrics/CyclomaticComplexity

          # rubocop:disable Metrics/CyclomaticComplexity
          def resource_uses_code(resource, system, code)
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
          # rubocop:enable Metrics/CyclomaticComplexity

          def extract_valueset_from_response(response)
            value_set = JSON.parse(response.body)

            if value_set['compose'] && value_set['compose']['include']
              value_set['compose']['include'].map do |include|
                include['concept']&.map { |concept| { system: include['system'], code: concept['code'] } }
              end.flatten
            else
              puts 'No Value Set found in the response.'
            end
          end

          def retrieve_valueset_from_api(url)
            url['http:'] = 'https:' if url['http:']
            uri = URI.parse(url)

            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = (uri.scheme == 'https')

            request = Net::HTTP::Get.new(uri.request_uri)

            username = config.data['Environment']['VSAC']['Username']
            password = config.data['Environment']['VSAC']['Password']
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
              extract_valueset_from_response(response)
            else
              unless config.data['Rule']['ValueSetsDemonstrate']['IgnoreUnloadableValueset']
                raise StandardError, "Failed to retrieve external value set: #{url} HTTP Status code: #{response.code}"
              end

              value_set_unevaluated << "#{url}: Failed to retrieve. HTTP Status code: #{response.code}"
              nil

            end
          end
        end
      end
    end
  end
end
