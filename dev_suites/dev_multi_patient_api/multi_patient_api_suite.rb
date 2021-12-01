Dir.glob(File.join(__dir__, '*.rb')).each { |path| require_relative path.delete_prefix("#{__dir__}/") }

module MultiPatientAPI
  class MultiPatientAPISuite < Inferno::TestSuite

    id 'multi_patient_api'
    title 'Multiple Patient API'

    group from: :bulk_data_access
  end
end 