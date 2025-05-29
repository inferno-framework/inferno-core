import React from 'react';
import { render, screen } from '@testing-library/react';
import { Test, TestGroup, TestSuite } from 'models/testSuiteModels';
import TestSuiteTree, { TestSuiteTreeProps } from '../TestSuiteTree';
import ThemeProvider from 'components/ThemeProvider';

import { expect, test, vi } from 'vitest';

vi.mock('react-router', () => ({
  useNavigate: () => {},
}));

const test1: Test = {
  id: 'test1',
  short_id: '1.1',
  title: 'FHIR server makes SMART configuration available from well-known endpoint',
  inputs: [],
  outputs: [],
  optional: false,
};
const test2: Test = {
  id: 'test2',
  short_id: '1.2',
  title: 'Well-known configuration contains required fields',
  inputs: [],
  outputs: [],
  optional: false,
};
const test3: Test = {
  id: 'test3',
  short_id: '2.1',
  title: 'Client registration endpoint secured by transport layer security',
  inputs: [],
  outputs: [],
  user_runnable: true,
  optional: false,
};
const test4: Test = {
  id: 'test4',
  short_id: '2.2',
  title: 'Client registration endpoint accepts POST messages',
  inputs: [],
  outputs: [],
  user_runnable: true,
  optional: false,
};

const testList1 = [test1, test2];
const testList2 = [test3, test4];

const sequence1: TestGroup = {
  tests: testList1,
  short_id: '1',
  test_groups: [],
  title: 'SMART on FHIR Discovery',
  id: 'group0',
  inputs: [{ name: 'test input' }],
  outputs: [],
  user_runnable: true,
  optional: false,
};

const sequence2: TestGroup = {
  tests: testList2,
  short_id: '2',
  test_groups: [],
  title: 'Dynamic Registration',
  id: 'group1',
  inputs: [{ name: 'second input' }],
  outputs: [],
  user_runnable: true,
  optional: false,
};

const nestedGroup: TestGroup = {
  tests: [],
  short_id: '3.1',
  test_groups: [],
  title: 'nested group',
  id: 'group2',
  inputs: [],
  outputs: [],
  user_runnable: true,
  optional: false,
};

const parentGroup: TestGroup = {
  tests: [],
  short_id: '3',
  test_groups: [nestedGroup],
  title: 'i have a nested group',
  id: 'group3',
  inputs: [],
  outputs: [],
  user_runnable: true,
  optional: false,
};

const demoTestSuite: TestSuite = {
  title: 'DemonstrationSuite',
  id: 'example suite',
  test_groups: [sequence1, sequence2, parentGroup],
  optional: false,
  inputs: [],
};

const testSuiteTreeProps: TestSuiteTreeProps = {
  testSuite: demoTestSuite,
  selectedRunnable: 'example suite',
  view: 'run',
};

test('Test tree renders', () => {
  render(
    <ThemeProvider>
      <TestSuiteTree {...testSuiteTreeProps} />
    </ThemeProvider>,
  );
  const treeTitle = screen.getByText(testSuiteTreeProps.testSuite.title);
  expect(treeTitle).toBeVisible();
  const sequence1Title = screen.getByText(sequence1.title);
  expect(sequence1Title).toBeVisible();
  const sequence2Title = screen.getByText(sequence2.title);
  expect(sequence2Title).toBeVisible();
  const parentGroupTitle = screen.getByText(parentGroup.title);
  expect(parentGroupTitle).toBeVisible();
  const nestedGroupTitle = screen.getByText(nestedGroup.title);
  expect(nestedGroupTitle).toBeVisible();
});

test('Individual tests are not shown by default', () => {
  render(
    <ThemeProvider>
      <TestSuiteTree {...testSuiteTreeProps} />
    </ThemeProvider>,
  );
  sequence1.tests.forEach((test) => {
    const testTitle = screen.queryByText(test.title);
    expect(testTitle).toBeNull();
  });
});

test('Requirements only shows in tree if they exist in the TestSuite', () => {
  render(
    <ThemeProvider>
      <TestSuiteTree {...{ ...testSuiteTreeProps, requirementsExist: true }} />
    </ThemeProvider>,
  );
  const requirementsLink = screen.queryByText('Specification Requirements');
  expect(requirementsLink).toBeInTheDocument();
});
