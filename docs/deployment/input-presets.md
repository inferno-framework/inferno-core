---
title: Input Presets
nav_order: 5
parent: Deployment
---
# Input Presets
{: .no_toc}

## Table of Contents
{: .no_toc .text-delta}

1. TOC
{:toc}
---
## Input Presets
Input presets are sets of predefined input values for a suite. Users can select
a preset to use those predefined values without having to manually enter them.
Presets must be placed in `config/presets`.

### Generating a Preset Template
The Inferno CLI can generate a preset template.

```
ᐅ inferno suite help input_template
Usage:
  inferno suite input_template SUITE_ID

Options:
  f, [--filename=<filename>]

Description:
  Generates a template for creating an input preset for a Test Suite.

  With -f option, the preset template is written to the specified filename.
```

Without the `-f` option, the preset template will just be displayed in the
console. With the `-f` option, the preset template will be written to
`config/presets` with the given filename. If you need to find out a test suite's
id, the `inferno suites` command will display the ids for all of the available
test suites.

The preset template will contain some metadata for the preset:
* `title` - This is what is displayed to users when selecting presets
* `id` - A unique id string for this preset. If `null`, a random id is generated
  for the preset when Inferno starts.
* `test_suite_id` - The id for the test suite this preset is for

The preset then contains a list of `inputs`. Set the `value` for each input, and
those values will be used when a user selects the preset. The input keys
beginning with underscores are ignored, and are included to assist in the
creation of a preset.

```json
{
  "title": "Preset for Demonstration Suite",
  "id": null,
  "test_suite_id": "demo",
  "inputs": [
    {
      "name": "url",
      "value": "https://inferno.healthit.gov/reference-server/r4",
      "_title": "URL",
      "_description": "Insert url of FHIR server",
      "_type": "text"
    },
    {
      "name": "patient_id",
      "value": "85",
      "_title": "Patient ID",
      "_type": "text"
    }
  ]
}
```

### Presets with Dynamic Values

It is possible for values in templates to be dynamically generated when Inferno
starts by using [embedded ruby (ERB)](https://github.com/ruby/erb). For example,
this could be used to have a preset with a host which is read from an
environment variable. In order to use ERB in a preset:

* Give the filename the `.erb` extension. For a JSON file with ERB, the
  extension `.json.erb` would be typical.
* Use the `<%= %>` ERB tag to insert ruby code which will be evaluated when
  Inferno starts. The tag will be replaced by the result of executing the ruby
  code within the tag.

```json
{
  "name": "url",
  "value": "<%= ENV['REFERENCE_SERVER_HOST'] %>/reference-server/r4",
  "_title": "URL",
  "_description": "Insert url of FHIR server",
  "_type": "text"
}
```

In the example above, if the `REFERENCE_SERVER_HOST` environment variable were
set to `http://example.com`, then that input would have a value of
`"http://example.com/reference-server/r4"`.

### Presets with Suite Options

It is possible to specify different values for a preset input depending on what
[suite
options](/inferno-core/writing-tests/test-configuration.html#suite-options-1)
have been selected. To do this, add a `value_for_options` key to the preset
input. Within `value_for_options`, add a list of `options` with `name` and
`value`, as well as the `value` to be used when those options are used. When
using the preset, if `value_for_options` is present, its entries are evaluated
in order. The value in the first entry whose options match the options selected
by the user will be used. The plain `value` (outside of `value_for_options`)
will be used if the selected options do not match any of the `value_for_options`
entries.

```json
{
  "name": "all_versions_input",
  "_type": "text",
  "value": "ig version 1 not selected",
  "value_for_options": [
    {
      "options": [
        {
          "name": "ig_version",
          "value": "1"
        },
        {
          "name": "other_option",
          "value": "1"
        }
      ],
      "value": "ig version 1 & other option 1 selected"
    },
    {
      "options": [
        {
          "name": "ig_version",
          "value": "1"
        },
        {
          "name": "other_option",
          "value": "2"
        }
      ],
      "value": "ig version 1 & other option 2 selected"
    }
  ]
}
```
