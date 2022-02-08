---
title: Writing Tests
nav_order: 5
has_children: true
---
# Writing Tests in Inferno
{: .no_toc}
---
## Test Suite Structure
There are three classes used to organize tests in Inferno:
- `TestSuite` - An entire suite of tests. A suite can contain many `TestGroup`s.
- `TestGroup` - A `TestGroup` can contain many `TestGroup`s or `Test`s.
- `Test` - An individual test. A test contains a `run` block which defines what
  happens when the test is run.

A simple US Core test suite might look like this:
- US Core (`TestSuite`)
  - US Core Patient Group (`TestGroup`)
    - Server supports Patient Read Interaction (`Test`)
    - Server supports Patient Search by id (`Test`)
  - US Core Condition Group (`TestGroup`)
    - Server supports Condition Read Interaction (`Test`)
    - Server supports Condition Search by Patient (`Test`)
