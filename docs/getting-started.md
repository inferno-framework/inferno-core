---
title: Getting Started
nav_order: 4
---
# Getting Started
{: .no_toc}

## Table of Contents
{: .no_toc .text-delta}

1. TOC
{:toc}
---
## Getting Started for Inferno Users
Start here if you're interested in testing a FHIR server against one or more existing Test Kits.

### A Single Test Kit
Most Test Kits are developed using the [Inferno Template 
repository](https://github.com/inferno-framework/inferno-template) which provides shell scripts for rapidly standing up
an instance of Inferno for that Test Kit

e.g. the [US Core Test Kit](https://github.com/inferno-framework/us-core-test-kit)

```sh
git clone https://github.com/inferno-framework/us-core-test-kit.git
./setup.sh
./run.sh
```

Always check the documentation for an individual test kit since they may differ from this standard approach

### One or More Test Kits
There may be times when you wish to offer multiple test kits in a single Inferno instance. If a test kit for this
composition doesn't already exist, you create a custom combination by using Inferno Core.

Inferno Deployment offers a stripped down template for creating and deploying a custom combination of test kits.

```sh
git clone https://github.com/inferno-framework/inferno-deployment.git
```

Test kits you want to include can then be added to `Gemfile`

e.g.
```ruby
gem 'smart_app_launch_test_kit',
    git: 'https://github.com/inferno-framework/smart-app-launch-test-kit.git',
    branch: 'main'
gem 'us_core_test_kit',
    git: 'https://github.com/inferno-framework/us-core-test-kit.git',
    branch: 'main'
```

To enable the test kits, require them in in `lib/inferno_deployment.rb`

```ruby
require 'smart_app_launch_test_kit'
require 'us_core_test_kit'
```

_Note: Test Kits shown can be filtered with a `Inferno::Repositories::TestSuites.all.select!` statement_

Inferno relies on external validation services for profile validation. For test kits that require profile validation,
such as the US Core Test Kit, the IG package.tgz will need to be placed in the `lib/inferno_deployment/igs/` directory.
The IG files can be located in the test kits git repository.

e.g. for the US Core Test Kit
```sh
git clone https://github.com/inferno-framework/us-core-test-kit.git
cp -a /us-core-test-kit/lib/us_core/igs/. /inferno_deployment/lib/inferno_deployment/igs/
```

Once this is done you can build and run the instance with

```sh
./setup.sh
./run.sh
```

## Getting Started for Inferno Test Writers

### Installation
1. Install [Docker](https://www.docker.com/get-started).
1. Clone the [Inferno Template
   repository](https://github.com/inferno-framework/inferno-template). You can
   either clone this repository directly, or click the green "Use this template"
   button to create your own repository based on this one.
1. Run `./setup.sh` in the template repository to retrieve the necessary docker
   images and create a database.
   
### Running Inferno
After installation, run the `./run.sh` script to start Inferno.
- Navigate to [localhost](http://localhost) to access Inferno and run test
  suites.
- Navigate to [localhost/validator](http://localhost/validator) to access a
  standalone validator that can be used to validate individual FHIR resources.

### Next Steps
Now that Inferno is running, you could learn about [the file/directory
organization](/inferno-core/repo-layout-and-organization.html) or just start
[writing tests](/inferno-core/writing-tests).
