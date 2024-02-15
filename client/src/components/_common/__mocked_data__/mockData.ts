import { Test, TestGroup, TestSuite } from 'models/testSuiteModels';

export const mockedTest: Test = {
  id: 'mock-test-id',
  title: 'Mock Test',
  inputs: [],
  short_id: 'test',
  outputs: [],
  user_runnable: true,
};

export const mockedUnrunnableTest: Test = {
  id: 'mock-unrunnable-test-id',
  title: 'Mock Unrunnable Test',
  inputs: [],
  short_id: 'unrunnable-test',
  outputs: [],
  user_runnable: false,
};

export const mockedTestGroup: TestGroup = {
  id: 'mock-test-group-id',
  title: 'Mock Test Group',
  inputs: [],
  short_id: 'test-group',
  test_groups: [],
  outputs: [],
  tests: [mockedTest],
};

export const mockedTestSuite: TestSuite = {
  id: 'mock-test-suite-id',
  title: 'Mock Test Suite',
  inputs: [],
  test_groups: [mockedTestGroup],
};
