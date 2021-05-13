import React from 'react';
import { fireEvent, render, screen, waitFor, within } from '@testing-library/react';
import { getTestResults, postTestRun } from 'api/infernoApiService';
import { mocked } from 'ts-jest/utils';
import { mockedTestRunReturnValue, mockedResultsReturnValue } from '../__mocked_data__/mockData';
import { TestSuite } from 'models/testSuiteModels';
import TestSession from '../TestSession';

const testSuite: TestSuite = {
  title: 'test suite',
  id: 'testSuite',
  test_groups: [
    {
      title: 'test group',
      id: 'testGroup',
      test_groups: [],
      tests: [],
      inputs: [],
      outputs: [],
    },
  ],
};

jest.mock('api/infernoApiService');
const mockedGetTestResults = mocked(getTestResults, true);
const mockedTestRun = mocked(postTestRun, true);
// need to mock resolved value in each test for some reason
const mockTestSession = {
  id: 'test session id',
  test_suite_id: testSuite.id,
  test_suite: testSuite,
};
test('test results are displayed after running', async () => {
  mockedTestRun.mockResolvedValue(mockedTestRunReturnValue);
  mockedGetTestResults.mockResolvedValue(mockedResultsReturnValue);
  render(<TestSession testSession={mockTestSession} previousResults={[]} />);
  const runButton = screen.getByTestId('testSuite-run-button');
  fireEvent.click(runButton);
  const testSuiteResult = mockedResultsReturnValue[0];
  await waitFor(() => {
    const testSuiteTitleArea = screen.getByTestId('testSuite-title');
    const resultIcon = within(testSuiteTitleArea).queryByTestId(
      `${testSuiteResult.id}-${testSuiteResult.result}`
    );
    expect(resultIcon).toBeVisible();
  });
});
