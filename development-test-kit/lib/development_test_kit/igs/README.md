# Note on this IGs folder

There are three reasons why it would be necessary to put an IG package.tgz in this folder. If none of these apply, you do not need to put any files here, or can consider removing any existing files to make it clear they are unused.

## 1. Generated Test Suites
Some test kits use a "generator" to automatically generate the contents of a test suite for an IG. The IG files are required every time the test suites need to be regenerated. Examples of test kits that use this approach are the US Core Test Kit and CARIN IG for Blue Button® Test Kit.


## 2. Non-published IG
If your IG, or the specific version of the IG you want to test against, is not published, then the validator service needs to load the IG from file in order to be able to validate resources with it. The IG must be referenced in the `fhir_resource_validator` block in the test suite definition by filename, ie:

```ruby
      fhir_resource_validator do
        igs 'igs/filename.tgz'

        ...
      end
```

## 3. Inferno Validator UI
The Inferno Validator UI is configured to auto-load any IGs present in the igs folder and include them in all validations. In general, the Inferno team is currently leaving IGs in this folder even if not otherwise necessary to make it easy to re-enable the validator UI.