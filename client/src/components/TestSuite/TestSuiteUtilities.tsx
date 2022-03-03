import { Test, TestGroup, TestInput, TestSuite } from 'models/testSuiteModels';

function inputAlreadyExists(existing_inputs: TestInput[], new_input: TestInput): boolean {
  return existing_inputs.some((existing_input: TestInput) => {
    return existing_input.name == new_input.name;
  });
}

export function getAllContainedInputs(testGroups: TestGroup[]): TestInput[] {
  const all_inputs: TestInput[] = [];
  const all_outputs: Set<string> = new Set();

  testGroups.forEach((subGroup) => {
    const subgroup_inputs: TestInput[] = getInputsRecursive(subGroup, all_outputs);
    subgroup_inputs.forEach((test_input: TestInput) => {
      if (!inputAlreadyExists(all_inputs, test_input)) {
        all_inputs.push(test_input);
      }
    });
  });
  return all_inputs;
}

function getInputsRecursive(testGroup: TestGroup, testOutputs: Set<string>): TestInput[] {
  let inputs = testGroup.inputs.filter((input) => !testOutputs.has(input.name));
  testGroup.test_groups.forEach((subGroup) => {
    inputs = inputs.concat(getInputsRecursive(subGroup, testOutputs));
  });
  testGroup.tests.forEach((test) => {
    inputs = inputs.concat(test.inputs.filter((input) => !testOutputs.has(input.name)));
    test.outputs.forEach((output) => testOutputs.add(output.name));
  });
  testGroup.outputs.forEach((output) => testOutputs.add(output.name));
  return inputs;
}

export const shouldShowDescription = (
  runnable: Test | TestGroup | TestSuite,
  description: JSX.Element | undefined
): boolean => {
  if (description && runnable.description && runnable.description.length > 0) {
    return true;
  } else {
    return false;
  }
};
