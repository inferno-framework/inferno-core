# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'
require 'base64'

module FhirEvaluator
  module Rules
    class ValueSetsDemonstrate < Rule
      attr_accessor :config

      def check(context)
        @config = context.config

        value_set_unevaluated = []
        value_set_used = []
        value_set_unused = []

        context.ig.value_sets.each do |valueset|
          cnt = 0
          system_codes = []

          if valueset.to_hash['compose']
            valueset.to_hash['compose']['include'].each do |include|
              if include['valueSet']
                include['valueSet'].each do |url|
                  retrieve_remote_valuesets(url)&.each { |vs| system_codes << vs }
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
                  retrieve_remote_valuesets(system_url)&.each { |vs| system_codes << vs }
                end
                next
              end

              value_set_unevaluated << valueset.url unless system_url

              # Exclude if system is provided as Uniform Resource Name "urn:"
              if @config.Rule.ValueSetsDemonstrate.Exclude.URL && (system_url['urn'])
                value_set_unevaluated << valueset.url
              end

              # Exclude filter
              if @config.Rule.ValueSetsDemonstrate.Exclude.Filter && (system_url && include['filter'])
                value_set_unevaluated << valueset.url
              end

              # Exclude only system is provided (e.g. http://loing.org)
              if @config.Rule.ValueSetsDemonstrate.Exclude.SystemOnly && (system_url && !include['concept'] && !include['filter'])
                value_set_unevaluated << valueset.url
              end
            end

          else
            # In case of value set does not have compose element
            value_set_unevaluated << valueset.url
          end
          system_codes.flatten.uniq!

          value_set_unevaluated << valueset.url if system_codes.none?

          next if value_set_unevaluated.include?(valueset.url)

          resource_used = []

          context.data.each do |resource|
            system_codes.each do |sys_code|
              if !sys_code.nil? && find_valueset_used(resource.to_hash, sys_code[:system], sys_code[:code])
                cnt += 1
                resource_used << resource.id unless resource_used.include?(resource.id)
              end
            end
          end

          if cnt.positive?
            value_set_used << "#{valueset.url} is used #{cnt} times in #{resource_used.count} resources"
          else
            value_set_unused << valueset.url
          end
        end

        value_set_unevaluated.uniq!

        if value_set_unused.none?
          message = 'All Value sets are used in Examples:'
          value_set_used.map { |vs| message += "\n\t#{vs}" }

          if value_set_unevaluated.any?
            message += "\nThe following Value Sets were not able to be evaluated: "
            value_set_unevaluated.map { |vs| message += "\n\t#{vs}" }
          end

          result = EvaluationResult.new(message, severity: 'success', rule: self)
        else
          message = 'All codes in these value sets are used at least once in Examples:'
          value_set_used.map { |vs| message += "\n\t#{vs}" }

          message += "\nFound unused Value Sets: "
          value_set_unused.map { |vs| message += "\n\t#{vs}" }

          if value_set_unevaluated.any?
            message += "\nFound unevaluated Value Sets: "
            value_set_unevaluated.map { |vs| message += "\n\t#{vs}" }
          end

          result = EvaluationResult.new(message, rule: self)
        end

        context.add_result result
      end

      def find_valueset_used(resource, system, code)
        resource.each do |key, value|
          next unless key == 'code' || ['value', 'valueCodeableConcept', 'valueString', 'valueQuantity', 'valueBoolean',
                                        'valueInteger', 'valueRange', 'valueRatio', 'valueSampleData', 'valueDateTime', 'valuePeriod', 'valueTime'].include?(key)
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

      def retrieve_remote_valuesets(url)
        url['http:'] = 'https:' if url['http:']
        uri = URI.parse(url)

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')

        request = Net::HTTP::Get.new(uri.request_uri)
        if url[@config.Rule.ValueSetsDemonstrate.VSAC.url]
          username = 'apikey'
          password = @config.Rule.ValueSetsDemonstrate.VSAC.apikey
          encoded_credentials = Base64.strict_encode64("#{username}:#{password}")
          request['Authorization'] = "Basic #{encoded_credentials}"
        end

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
