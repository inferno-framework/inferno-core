---
layout: home
title: Home
nav_order: 1
---
# Inferno
{: .fs-9 }

Everything you need to create, execute and share tests for health IT systems providing standardized FHIR APIs.
{: .fs-6 .fw-300}

[Get started now](/inferno-core/getting-started){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 } [Read the Docs](/inferno-core/overview){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2 } [View it on GitHub](https://github.com/inferno-framework/){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2 }

Simple to Read, Simple to Write
{: .fs-7 .fw-300 }
Inferno tests are written in a Ruby DSL, with a focus on readability.
{: .fs-4 }

```ruby
test do
  title 'Server returns requested Patient resource from the Patient read interaction'
  description %(
        Verify that Patient resources can be read from the server.
      )

  input :patient_id
  # Named requests can be used by other tests
  makes_request :patient

  run do
    fhir_read(:patient, patient_id, name: :patient)

    assert_response_status(200)
    assert_resource_type(:patient)
    assert resource.id == patient_id,
           "Requested resource with id #{patient_id}, received resource with id #{resource.id}"
  end
end
```

Continuous Integration Ready
{: .fs-7 .fw-300 }
Inferno exposes a JSON API for automated execution within your CI pipeline.
{: .fs-4 .d-flex .flex}
```http
GET /api/test_suites

[
  {
    "id": "ONCProgram::Suite",
    "description": "ONC Standardized API Testing ",
    "test_count": 427,
    "title": "2015 Edition Cures Update -  Standardized API Testing"
  }
]
```

Create, Share, Extend
{: .fs-7 .fw-300 }
Inferno Test Kits can be easily shared and extended so you can focus on your unique tests.
{: .fs-4 .d-flex .flex}
```ruby
require 'smart_app_launch_test_kit'

module MyTestKit
  class MyTestSuite < Inferno::TestSuite
    group from: :smart_discovery
  end
end
```
