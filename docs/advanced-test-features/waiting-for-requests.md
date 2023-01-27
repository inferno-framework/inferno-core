---
title: Waiting for an Incoming Request
nav_order: 3
parent: Advanced Features
---
# Waiting for an Incoming Request
{: .no_toc}

## Table of Contents
{: .no_toc .text-delta}

1. TOC
{:toc}
---
## Overview
Some testing workflows required testing to pause until an incoming request is
received. For example, the OAuth2 workflow used by the SMART App Launch IG
involves redirecting the user to an authorization server, which then redirects
the user back to the application which requested authorization (Inferno). In
order to handle a workflow like this, Inferno must be able to handle the
incoming request and associate it with a particular testing session. Inferno
accomplishes this with the `wait` status and special routes for resuming tests.

### Making a Test Wait
A test is instructed to wait for an incoming request using the
[`wait`](/inferno-core/docs/Inferno/DSL/Results.html#wait-instance_method)
method. `wait` takes three arguments:
* `identifier` - An identifier which can uniquely identify the current test
  session. It must be possible for this identifier to be reconstructed based on
  the incoming request.
* `message` - A markdown string which will be displayed to the user while the
  test is waiting.
* `timeout` - The number of seconds the test will wait.

[`wait` in the API
docs](/inferno-core/docs/Inferno/DSL/Results.html#wait-instance_method)

### Handling the Incoming Request
The route to make a test resume execution is created with
[`resume_test_route`](/inferno-core/docs/Inferno/DSL/Runnable.html#resume_test_route-instance_method),
which takes three arguments:
* `method` - A symbol for the HTTP verb for the incoming request (`:get`,
  `:post`, etc.)
* `path` - A string for the route path. The route will be served at
  `INFERNO_BASE/custom/SUITE_ID/CUSTOM_ROUTE_PATH`.
* A block which extracts `identifier` from the incoming request and returns it.
  In this block, `request` can be used to access a [`Request`
  object](/inferno-core/docs/Inferno/Entities/Request.html) which contains the
  details of the incoming request.
  
If it is necessary to inspect the incoming request in a test, the incoming
request can be assigned a name using `receives_request :my_request_name` (see
[Reusing
Requests](/inferno-core/writing-tests/making-requests.html#reusing-requests)).

[`resume_test_route` in the API
docs](/inferno-core/docs/Inferno/DSL/Runnable.html#resume_test_route-instance_method)

[`receives_request` in the API
docs](/inferno-core/docs/Inferno/DSL/RequestStorage/ClassMethods.html#receives_request-instance_method)

## Example
This example will show how to implement the redirect flow in the [SMART App
Launch Standalone Launch
Sequence](http://hl7.org/fhir/smart-app-launch/1.0.0/#standalone-launch-sequence).
It will be necessary to:
* Redirect the user to the system under test's authorize endpoint.
  * The client (Inferno) generates a random `state` value which the
    authorization server sends back, so `state` can be used as the `identifier`.
* Wait for the user to be redirected back to Inferno.
  * Extract `state` from the incoming request to match the current test session.
* Check that the incoming request contained a `code` parameter.

```ruby
class SMARTAppLaunchSuite < Inferno::TestSuite
  id :smart_app_launch
  
  # This route will be served at INFERNO_BASE/custom/smart_app_launch/redirect
  # Since the `state` query parameter is what uniquely links the incoming request
  # to the current test session, return that from the block.
  resume_test_route :get, '/redirect' do |request|
    request.query_parameters['state']
  end
  
  group do
    id :standalone_launch
    
    test do
      id :smart_redirect
      
      # Assign a name to the incoming request so that it can be inspected by
      # other tests.
      receives_request :redirect
      
      run do
        # Generate a random unique state value which uniquely identifies this
        # authorization request.
        state = SecureRandom.uuid
        
        # Build authorization url based on information from discovery, app
        # registration, and state.
        authorization_url = ...
        
        # Make this test wait.
        wait(
          identifier: state,
          message: %(
            [Follow this link to authorize with the SMART server](#{authorization_url}).

            Tests will resume once Inferno receives a request at
            `#{Inferno::Application['base_url']}/custom/smart_app_launch/redirect`
            with a state of `#{state}`.
          )
        )
      end
    end
    
    # Execution will resume with this test once the incoming request is
    # received.
    test do
      id :redirect_contains_code
      
      # Make the incoming request from the previous test available here.
      uses_request :redirect
      
      run do
        code = request.query_parameters['code']
        
        assert code.present?, 'No `code` parameter received'
      end
    end
  end
end
```
