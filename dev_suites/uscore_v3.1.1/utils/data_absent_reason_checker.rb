# frozen_string_literal: true

module USCore
  module DataAbsentReasonChecker
    DAR_EXTENSION_URL = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason'
    DAR_CODE_SYSTEM_URL = 'http://terminology.hl7.org/CodeSystem/data-absent-reason'

    def check_for_data_absent_reasons
      proc do |reply|
        check_for_data_absent_extension(reply)
        check_for_data_absent_code(reply)
      end
    end

    private

    def check_for_data_absent_extension(reply)
      return if scratch[:data_absent_extension_found]

      return unless contains_data_absent_extension?(reply[:body])

      scratch[:data_absent_extension_found] = true
    end

    def check_for_data_absent_code(reply)
      return if scratch[:data_absent_code_found]

      return unless contains_data_absent_code?(reply[:body])

      scratch[:data_absent_code_found] = true
    end

    def contains_data_absent_extension?(body)
      body.include? DAR_EXTENSION_URL
    end

    def contains_data_absent_code?(body)
      return false unless body.include? DAR_CODE_SYSTEM_URL

      walk_resource(FHIR.from_contents(body)) do |element, meta, _path|
        next unless meta['type'] == 'Coding'

        return true if data_absent_coding?(element)
      end

      false
    end

    def data_absent_coding?(coding)
      coding.code == 'unknown' && coding.system == DAR_CODE_SYSTEM_URL
    end
  end
end
