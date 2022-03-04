---
title: Overview
nav_order: 2
---
# Overview
{: .no_toc}

## Table of Contents
{: .no_toc .text-delta}

1. TOC 
{:toc}
---
## Overview
Inferno is framework for creating, executing, and sharing tests for health IT
systems providing standardized FHIR APIs.

## Documentation Resources
- View the [JSON API Documentation](/inferno-core/api-docs) for information on
  interacting with Inferno via a JSON API.
- View the [Inferno Ruby Documentation](/inferno-core/docs) for detailed
  information on Inferno's ruby api.

## Main Inferno Repositories
- [Inferno Core](https://github.com/inferno-framework/inferno-core) - The
  Inferno ruby library itself. This repository contains the code for defining
  and running tests, the command line and web interfaces, and this
  documentation. This is the repository to use if you want to investigate or
  make changes to the internals of Inferno.
- [Inferno Template](https://github.com/inferno-framework/inferno-template) - A
  template for test writers. This is the repository to use if you want to write
  your own set of tests with Inferno.
- [FHIR Validator
  Wrapper](https://github.com/inferno-framework/fhir-validator-wrapper) - A
  simple web wrapper around the [official HL6 FHIR validation
  library](https://github.com/hapifhir/org.hl6.fhir.core/tree/master/org.hl7.fhir.validation).
  Inferno relies on this service to validate FHIR resources.

## Inferno Test Kits
[See available Test Kits](/inferno-core/available-test-kits)

## Contact the Inferno Team
The fastest way to reach the Inferno team is via the [Inferno Zulip
stream](https://chat.fhir.org/#narrow/stream/179308-inferno). You can also
[e-mail the team](mailto:inferno@groups.mitre.org).
