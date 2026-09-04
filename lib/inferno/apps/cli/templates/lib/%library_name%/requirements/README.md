# Using Core Requirements Tools

This directory contains [requirement artifacts](https://inferno-framework.github.io/docs/advanced-test-features/requirements.html)
that contain example requirements that could be linked to tests
within this test kit and displayed within the UI as justification
for the tests.

Each `.xlsx` file defined in this directory will contribute towards the
test kit's requirements and a GitHub workflow executed automatically on pull
requests checks that these files are in sync with the generated requirement
list and coverage analysis `.csv` files. If no `.xlsx` files are found in
this directory, the GitHub workflow will be skipped. 