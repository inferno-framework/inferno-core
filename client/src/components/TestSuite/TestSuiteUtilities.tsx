import { TestSuite, TestGroup, Test, TestInput, RunnableType } from 'models/testSuiteModels';

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

// We have to pass in `kind` with `runnable` because Typescript can't look at our runnable
// union and know the type other than `Object`.  So we pass an instance but also the kind
// as metadata which is not optimal.  A better thing might be to use a class hierarchy.
export const setInCurrentTestRun = (
  runnable: TestSuite | TestGroup | Test,
  kind: RunnableType
): void => {
  switch (kind) {
    case RunnableType.TestSuite:
      runnable.isInCurrentTestRun = true;
      (runnable as TestSuite).test_groups?.forEach((testGroup: TestGroup) => {
        setInCurrentTestRun(testGroup, RunnableType.TestGroup);
      });
      break;
    case RunnableType.TestGroup:
      runnable.isInCurrentTestRun = true;
      (runnable as TestGroup).test_groups?.forEach((testGroup: TestGroup) => {
        setInCurrentTestRun(testGroup, RunnableType.TestGroup);
      });
      (runnable as TestGroup).tests?.forEach((test: Test) => {
        setInCurrentTestRun(test, RunnableType.Test);
      });
      break;
    case RunnableType.Test:
      runnable.isInCurrentTestRun = true;
      break;
  }
};
