---
title: Distributing Tests
nav_order: 7
---
# Distributing Tests
{: .no_toc}
---
Inferno allows test kits to be distributed like regular ruby gems. In order to
make your test suite available to others, first it needs to be organized as
described in [Test
Organization](/inferno-core/repo-layout-and-organization.html#test-organization).

Then, you must fill in the information in the `gemspec` file in the root of the
repository. The name of the file should match `spec.name` within the file and
the name of the main file in `lib`. Using the US Core example from above, this
file would be named `us_core_test_kit.gempsec` and `spec.name` would be
`'us_core_test_kit'`. There are [recommended naming conventions for
gems](https://guides.rubygems.org/name-your-gem/).

**Optional:** Once your gemspec file has been updated, you can publish your gem
on [rubygems, the official ruby gem repository](https://rubygems.org/). If you
don't publish your gem on rubygems, users will still be able to install it if it
is located in a public git repository. To publish your gem on rubygems, you will
first need to [make an account on
rubygems](https://guides.rubygems.org/publishing/#publishing-to-rubygemsorg) and
then run `gem build *.gemspec` and `gem push *.gem`.
