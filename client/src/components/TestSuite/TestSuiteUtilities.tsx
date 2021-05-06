import { Tooltip } from '@material-ui/core';
import { Result, TestGroup, TestInput } from 'models/testSuiteModels';
import { green, red } from '@material-ui/core/colors';
import CheckIcon from '@material-ui/icons/Check';
import CancelIcon from '@material-ui/icons/Cancel';
import ErrorIcon from '@material-ui/icons/Error';
import { RedoOutlined } from '@material-ui/icons';
import RadioButtonUncheckedIcon from '@material-ui/icons/RadioButtonUnchecked';
import React, { Fragment } from 'react';

function inputAlreadyExists(existing_inputs: TestInput[], new_input: TestInput): boolean {
  return existing_inputs.some((existing_input: TestInput) => {
    return existing_input.name == new_input.name;
  });
}

export function getAllContainedInputs(testGroups: TestGroup[]): TestInput[] {
  const all_inputs: TestInput[] = [];
  testGroups.forEach((subGroup) => {
    const subgroup_inputs: TestInput[] = getInputsRecursive(subGroup);
    subgroup_inputs.forEach((test_input: TestInput) => {
      if (!inputAlreadyExists(all_inputs, test_input)) {
        all_inputs.push(test_input);
      }
    });
  });
  return all_inputs;
}

function getInputsRecursive(testGroup: TestGroup): TestInput[] {
  let inputs = testGroup.inputs;
  testGroup.test_groups.forEach((subGroup) => {
    inputs = inputs.concat(getInputsRecursive(subGroup));
  });
  testGroup.tests.forEach((test) => {
    inputs = inputs.concat(test.inputs);
  });
  return inputs;
}

export function getIconFromResult(result: Result | undefined): JSX.Element {
  if (result) {
    switch (result.result) {
      case 'pass':
        return (
          <Tooltip title="passed">
            <CheckIcon
              style={{ color: green[500] }}
              data-testid={`${result.id}-${result.result}`}
            />
          </Tooltip>
        );
      case 'fail':
        return (
          <Tooltip title="failed">
            <CancelIcon style={{ color: red[500] }} data-testid={`${result.id}-${result.result}`} />
          </Tooltip>
        );
      case 'skip':
        return (
          <Tooltip title="skipped">
            <RedoOutlined data-testid={`${result.id}-${result.result}`} />
          </Tooltip>
        );
      case 'omit':
        return (
          <Tooltip title="omitted">
            <RadioButtonUncheckedIcon data-testid={`${result.id}-${result.result}`} />
          </Tooltip>
        );
      case 'error':
        return (
          <Tooltip title="error">
            <ErrorIcon style={{ color: red[500] }} data-testid={`${result.id}-${result.result}`} />
          </Tooltip>
        );
      default:
        return <Fragment />;
    }
  } else {
    return <Fragment />;
  }
}
