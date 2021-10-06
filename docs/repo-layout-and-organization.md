---
title: Test Kit Repository Layout and Organization
nav_order: 3
---
# Test Kit Repository Layout and Organization
{: .no_toc}

## Table of Contents
{: .no_toc .text-delta}

1. TOC
{:toc}
---
## Template Layout
After cloning the template repository, you will have a directory structure that
looks something like this:
```
├── Dockerfile
├── config
│   └── ...
├── config.ru
├── data
│   └── redis
│       └── ...
├── docker-compose.yml
├── inferno_template.gemspec
├── lib
│   ├── inferno_template
│   │   └── igs
│   │       └── ...
│   └── inferno_template.rb
├── spec
│   ├── ...
└── worker.rb
```
- `Dockerfile` - This controls how the docker image for your tests is built.
- `Gemfile` - This is where you add extra ruby dependencies.
- `config` - This folder contains configuration for the database and web
  servers.
- `config.ru` - This is the main file for the Inferno's web server process.
- `data` - Database and redis snapshots live here.
- `docker-compose.yml` - This coordinates and runs all of the serivces inferno
  needs.
- `inferno_template.gemspec` - This file controls how your tests can be packaged
  up as a distributable ruby gem. This is also where you can add additional ruby
  gems if you need them.
- `lib` - This is where the code for your tests will live.
- `lib/{YOUR_TEST_KIT_NAME}/igs` - This is where IG packages go so that they can
  be used by the validator.
- `spec` - Unit tests live here.
- `worker.rb` - This is the main file for Inferno's test runner process.

## Test Organization
Inferno test kits are organized like ruby gems to enable them to be easily
distributed.
- Tests must live in the `lib` folder.
- The `lib` folder should contain only one file, which is the main entrypoint
  for your test suite. The name of this file should be `your_test_kit_name.rb`,
  and this is what people will `require` in order to load your tests.
- All other test files should live in a subdirectory in `lib`, and
  conventionally this subdirectory has the same name as the single file in `lib`
  without the extension.
- The `package.tgz` file for the IG you're test against should be placed in
  `lib/your_test_kit_name/igs`. This will allow you to validate against the
  profiles in that IG.

For example, if I were creating a test kit for the US Core Implementation Guide,
my `lib` folder might look like this:
```
lib
├── us_core_test_kit.rb
└── us_core_test_kit
    ├── patient_tests.rb
    ├── condition_tests.rb
    ├── ...
    └── igs
        └── package.tgz
```
And anyone wanting to use this test kit, would load it with `require
'us_core_test_kit'`. Check out [existing test
kits](/inferno-core/#inferno-test-kits) for examples.
