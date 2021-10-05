---
title: Getting Started
nav_order: 2
---
# Getting Started
{: .no_toc}

## Table of Contents
{: .no_toc .text-delta}

1. TOC
{:toc}
---
## Installation
1. Install [Docker](https://www.docker.com/get-started).
1. Clone the [Inferno Template
   repository](https://github.com/inferno-community/inferno-template). You can
   either clone this repository directly, or click the green "Use this template"
   button to create your own repository based on this one.
1. Run `./setup.sh` in the template repository to retrieve the necessary docker
   images and create a database.
   
## Running Inferno
After installation, run the `./run.sh` script to start Inferno.
- Navigate to [localhost](http://localhost) to access Inferno and run test
  suites.
- Navigate to [localhost/validator](http://localhost/validator) to access a
  standalone validator that can be used to validate individual FHIR resources.

## Next Steps
Now that Inferno is running, you could learn about [the file/directory
organization](/repo-layout-and-organizatiot.html) or just start [writing
tests](/writing-tests).
