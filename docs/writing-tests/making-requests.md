---
title: Making Requests
nav_order: 4
parent: Writing Tests
---
# Making Requests
{: .no_toc}

## Table of Contents
{: .no_toc .text-delta}

1. TOC
{:toc}
---
## Overview
Inferno provides support for making FHIR and generic http requests.

### Accessing Requests and Responses
After making a FHIR/http request, information about it is made available via several
methods:
- `request` - returns a
  [`Request`](/inferno-core/docs/Inferno/Entities/Request.html) object which
  contains all of the information about the request and the response.
- `response` - returns a Hash containing the `status`, `headers`, and `body` of
  the response.
- `resource` - returns the response body as a FHIR model.

```ruby
test do
  run do
    fhir_read(:patient, '123')
    
    request  # A `Request` object containing the request and response
    response # A `Hash` containing the response information
    resource # A FHIR model built from the response body
  end
end
```

When making [assertions](/inferno-core/docs/Inferno/DSL/Assertions.html) against
a response or resource, the assertions which are designed to be used with
responses and resources will automatically use the response/resource from the
last request, so it isn't necessary to pass one in unless you want to make
assertions against a different response/resource.

```ruby
test do
  run do
    fhir_read(:patient, '123')
    
    assert_response_status(200)
    assert_resource_type(:patient)
    assert_valid_resource
    
    ...
    
    assert_response_status(200, responce: some_other_response)
    assert_resource_type(:patient, resource: some_other_resource)
    assert_valid_resource(resource: some_other_resource)
  end
end
```

### Reusing Requests
You may want to reuse a request from an earlier test rather than reissuing it.
This can be done by giving a request a name, specifying that a test makes a
named request, and then specifying that another test uses that named request.

```ruby
group do
  test do
    # Declare that this test makes a particular request
    makes_request :patient_read
    
    run do
      fhir_read(:patient, '123', name: :patient_read) # include the name
    end
  end
  
  test do
    # Declare that this test uses a particular named request. The test runner
    # will automatically load this request and make it available within the test.
    uses_request :patient_read
    
    run do
      # These will all be populated with the request from the first test
      request
      response
      resource
    end
  end
end
```

## FHIR Requests

### FHIR Clients
Before making a FHIR request, a client needs to be created. Clients are passed
down from a `TestSuite` or `TestGroup` to all of their descendants, so it isn't
necessary for each `Test` to define its own client. When defining a client, you
MUST set the base server url, and you MAY set a bearer token and additional
custom headers.

```ruby
group do
  fhir_client do
    url 'https://example.com/fhir'   # required
    bearer_token 'abc'               # optional
    headers 'X-Custom-Header': 'def' # optional
  end
  
  test do
    run do
      # FHIR requests will automatically use the client declared above
    end
  end
end
```

You probably don't want to hard code the server url or bearer token, so a ruby
symbol can be used to read these values from an input.

```ruby
group do
  input :server_url, :access_token
  
  fhir_client do
    url :server_url
    bearer_token :access_token
  end
end
```

If you need direct access to the FHIR client in a test, it is available via
`client`. The client is reinstantiated in each test, so changes made to a client
within a test do not carry over into other tests.

```ruby
test do
  run do
    client # this returns the FHIR client
  end
end
```
[methods for defining FHIR clients in the API docs](/inferno-core/docs/Inferno/DSL/FHIRClientBuilder.html)

### Available FHIR Request Methods
The following methods are currently available for making FHIR requests:
- `fhir_get_capability_statement`
- `fhir_read`
- `fhir_search`
- `fhir_operation`
For more details on these methods, see the [FHIR Client API
documentation](/inferno-core/docs/Inferno/DSL/FHIRClient.html). If you need to
make other types of FHIR requests, [contact the Inferno
team](/#contact-the-inferno-team) so we can prioritize adding them.

### Making Requests to Multiple Servers
If you need to make requests to multiple fhir servers, this can be accomplished
by creating multiple named fhir clients.

```ruby
group do
  fhir_client :client_a do
    url :url_a
  end
  
  fhir_client :client_b do
    url :url_b
  end
  
  test do
    run do
      fhir_read(:patient, '123', client: :client_a)
      
      fhir_read(:patient, '456', client: :client_b)
    end
  end
end
```

## HTTP Requests

### HTTP Clients
It is not necessary to create an http client in order to make http requests, but
it may be helpful if you need to make multiple requests to the same server. If
an http client is available, then the http request methods only need to specify
the additional path which needs to be added to the client's url rather than an
absolute url.The syntax for doing so is the same as that for [FHIR
clients](#fhir-clients), except the method is called `http_client` rather than
`fhir_client`.

```ruby
group do
  http_client do
    url 'https://example.com'
    bearer_token 'abc'
    headers 'X-Custom-Header': 'def'
  end
  
  test do
    run do
      get '/path'  # Makes a request to `https://example.com/path`
    end
  end
end

```

### Available HTTP Request Methods
The following methods are currently available for making http requests:
- `get`
- `post`
For more details on these methods, see the [HTTP Client API
documentation](/inferno-core/docs/Inferno/DSL/HTTPClient.html). If you need to
make other types of http requests, [contact the Inferno
team](/#contact-the-inferno-team) so we can prioritize adding them.
