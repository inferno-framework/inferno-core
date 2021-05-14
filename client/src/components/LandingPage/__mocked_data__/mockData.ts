import { TestSuite } from 'models/testSuiteModels';

export const mockedTestSuitesReturnValue: TestSuite[] = [
  { id: 'DemoIG_STU1::DemoSuite', title: 'Demonstration Suite' },
  { id: 'infra_test', title: 'Infrastructure Test' },
];

export const mockedPostTestSuiteResponse = {
  id: '4402e8b1-8cd3-4dad-ba80-ffa593f26be4',
  test_suite: {
    id: 'DemoIG_STU1::DemoSuite',
    test_groups: [],
    title: 'Demonstration Suite',
  },
  test_suite_id: 'DemoIG_STU1::DemoSuite',
};
