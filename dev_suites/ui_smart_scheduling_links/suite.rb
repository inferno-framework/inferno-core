module SMARTSchedulingLinks
  class Suite < Inferno::TestSuite
    title 'SMART Scheduling Links (Draft Tests)'
    description 'SMART Scheduling Links (Draft; 1 April)'

    group do
      title 'SMART Scheduling Links - Slot Publisher Tests'
      description 'Retrieve and validate resources from a SMART Scheduling Links schedule publisher'

      test do
        title 'Manifest is valid URL ending in $bulk-publish.'
      end

      test do
        title 'Manifest file can be downloaded and is valid JSON.'
      end

      test do
        title 'Manifest is structured properly and contains required keys.'
      end

      test do
        title 'State-level jurisdiction information is valid if included.'
      end

      test do
        title 'Request with since parameter filters data.'
      end

      test do
        title 'Location ndjson files contain valid FHIR resources that have all required fields.'
      end

      test do
        title 'Location resources contain optional district.'
      end

      test do
        title 'Location resources contain optional description'
      end

      test do
        title 'Location resources contain optional position'
      end

      test do
        title 'Schedule resources have valid reference fields.'
      end

      test do
        title 'Slot ndjson files contain valid FHIR resources that have all required fields.'
      end

      test do
        title 'Slot contains valid references.'
      end
    end
  end
end
