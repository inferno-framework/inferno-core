import { TestSuite } from 'models/testSuiteModels';

export const mockedTestSuitesReturnValue: TestSuite[] = [
  { id: 'demo', title: 'Demonstration Suite', description: '', optional: false, inputs: [] },
  { id: 'infra_test', title: 'Infrastructure Test', description: '', optional: false, inputs: [] },
];

export const mockedPostTestSuiteResponse = {
  id: '4402e8b1-8cd3-4dad-ba80-ffa593f26be4',
  test_suite: {
    id: 'demo',
    test_groups: [],
    title: 'Demonstration Suite',
  },
  test_suite_id: 'demo',
};
