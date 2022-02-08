---
title: Concepts
nav_order: 2
---
# Concepts
{: .no_toc}

## Table of Contents
{: .no_toc .text-delta}

1. TOC
{:toc}
---
## Key Terms
- **Inferno Test Kit**: A distributable set of tests and tools built and packaged
  using Inferno to help testers evaluate the conformance of a system to
  requirements of the FHIR base specification, relevant FHIR Implementation
  Guides, and any additional requirements.  Example: the ONC g10 certification
  test kit. Test kits primarily are composed of a Test Suite, which represents
  executable tests, but may include other tools such as FHIR resource validators
  or reference implementations.  
- **Inferno Deployment**: A web host that is running
  one or more Inferno Test Kits.  Inferno Test Kits can be run as an Inferno Deployment on
  users local machines without any additional configuration. Alternately, an
  Inferno Deployment can host multiple Inferno Test Kits and run on a shared
  service, such as is the case for https://inferno.healthit.gov.  A deployment
  provides a web interface as well as a RESTful API to enable third party
  integration.
- **Inferno Test Suite**: An executable set of tests provided within an Inferno
  Test Kit that allows testers to evaluate the conformance of a system.  The tests
  are organized hierarchically.  They may import tests from other Test Kits.  It
  may be the expectation of a Test Suite that a conformant system will pass all
  provided tests, or that the system may fail some tests.  An individual test
  suite defines how to interpret failures at the test level and in aggregate.
- **Inferno Core**: The primary library of inferno, which testers can use to
  build Inferno Test Kits.  It provides the main logic of Inferno.  It provides a
  CLI, a web interface for executing tests, integration with data persistence
  layers and 3rd party validators.  Conceptually, Inferno core is similar to Ruby
  on Rails or React + create-react-app.
- **Inferno Template**: A starting point for writing new Inferno Test Suites.
- **Inferno Test DSL**: A Domain Specific Language (DSL) that test writers use to
  define the tests provided in the Inferno Test Suite. The DSL provides
  built-in functionality useful in testing FHIR APIs, such as FHIR client
  and built-in assertion libraries.  See documentation.
- **Inferno Validators**: Tools that validate the correctness of a piece of data
  against a set of rules defined within a context.  Inferno Tests typically fetch
  data and validate the response using a validator.  Examples: FHIR Profile
  Validator, FHIR Terminology Validator.  Inferno typically performs these
  functions by providing common third party validators (e.g. HL7 FHIR Validator).
- **Inferno Reference Implementations**: An Inferno Test Kit may may provide one or more Reference
  Implementations, which can be useful to develop tests against or to help interact
  with third party solutions.  Example: G10 Reference API.