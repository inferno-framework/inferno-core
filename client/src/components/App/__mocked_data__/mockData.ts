import { TestSuite, TestSession } from 'models/testSuiteModels';

export const testSuites: TestSuite[] = [
  {
    id: 'one',
    title: 'Suite One',
    description: '',
    optional: false,
    inputs: [],
  },
  {
    id: 'two',
    title: 'Suite Two',
    description: '',
    optional: false,
    inputs: [],
  },
];

export const singleTestSuite: TestSuite[] = [
  {
    id: 'one',
    title: 'Suite One',
    description: '',
    optional: false,
    inputs: [],
  },
];

export const testSession: TestSession = {
  id: '42',
  test_suite: singleTestSuite[0],
  test_suite_id: 'test-suite-id',
};
