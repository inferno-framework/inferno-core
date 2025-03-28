# frozen_string_literal: true

module Inferno
  module DSL
    module FHIREvaluation
      module Rules
        class DifferentialContentHasExamples < Rule
          def check(context)
            unused_differential = Hash.new { |field, url| field[url] = Set.new }
            collect_profile_differential_content(unused_differential, context.ig.profiles)
            collect_profile_differential_content(unused_differential, context.ig.extensions)
            remove_found_differential_content(unused_differential, context.data)

            if unused_differential.any? { |_url, diff| !diff.empty? }
              message = gen_differential_fail_message(unused_differential)
              result = EvaluationResult.new(message, rule: self)
            else
              message = 'All differential fields are represented in instances'
              result = EvaluationResult.new(message, severity: 'success', rule: self)
            end

            context.add_result result
          end

          def collect_profile_differential_content(unused_differential, profiles)
            profiles.each do |profile|
              profile.each_element do |value, _metadata, path|
                next unless path.start_with? 'differential'

                next unless value.is_a? FHIR::ElementDefinition
                next unless value.id.include? '.'

                # Skip fields that are disallowed by the profile (cardinality 0..0)
                # Note that max is a string to allow for "*", not an int
                next if value.max == '0'

                # TODO: discriminate between extensions
                # if you have field.extension:A and field.extension:B
                # only field.extension is recorded and checked for
                # if A and B are not defined in the IG,they may be missed
                clean_val = clean_value(value)

                unused_differential[profile.url].add(clean_val)
              end
            end
          end

          # rubocop:disable Metrics/CyclomaticComplexity
          def remove_found_differential_content(unused_differential, examples)
            examples.each do |resource|
              extension_base_path = ''
              extension_url = ''
              resource.each_element do |value, _metadata, path|
                profiles = resource&.meta&.profile || []
                profiles.each do |profile|
                  processed_path = plain_value(path)
                  processed_path = rm_brackets(processed_path)

                  if path.match?('extension\[\d+\]\.url$')
                    extension_base_path = path.rpartition('.').first
                    extension_url = value
                    unused_differential[extension_url].delete('url') if unused_differential.key?(extension_url)
                    unused_differential[extension_url].delete('extension') if unused_differential.key?(extension_url)
                    unused_differential.delete(extension_url) if unused_differential[extension_url].empty?
                  elsif path.start_with?(extension_base_path) && !extension_base_path.empty?
                    if unused_differential.key?(extension_url)
                      unused_differential[extension_url].delete(processed_path.rpartition('.').last)
                    end
                    unused_differential.delete(extension_url) if unused_differential[extension_url].empty?
                  else
                    unused_differential[profile].delete(processed_path) if unused_differential.key?(profile)
                    unused_differential.delete(profile) if unused_differential[profile].empty?
                  end
                end
              end
            end
          end
          # rubocop:enable Metrics/CyclomaticComplexity

          def clean_value(value)
            stripped_val = value.id.partition('.').last
            stripped_val = stripped_val.partition('[').first if stripped_val.end_with? ']'
            stripped_val.split('.').map do |field|
              field = field.partition(':').first if field.include?(':')
              field = field.partition('[').first if field.include?('[')
              field
            end.join('.')
          end

          def plain_value(path)
            if path.include? '.'
              path_array = path.split('.').map! do |field|
                field.start_with?('value') ? 'value' : field
              end
              path_array.join('.')
            elsif path.start_with?('value')
              'value'
            elsif path.end_with?(']')
              path.rpartition('[').first
            else
              path
            end
          end

          def rm_brackets(path)
            path_array = path.split('.').map! do |field|
              field.include?('[') ? field.partition('[').first : field
            end
            path_array.join('.')
          end

          def gen_differential_fail_message(unused_differential)
            "Found fields highlighted in the differential view, but not used in instances: #{
                            unused_differential.map do |url, field|
                              next if field.empty?

                              "\n Profile/Extension: #{url}  \n\tFields: #{field.join(', ')}"
                            end.compact.join}"
          end
        end
      end
    end
  end
end
