require 'health_cards'

module Covid19VCI
  class Suite < Inferno::TestSuite
    id 'c19-vci'
    title 'COVID-19 Vaccine Credential'

    # group do
    #   id 'vci-fhir-download'
    # end

    group from: :vci_file_download
  end
end
