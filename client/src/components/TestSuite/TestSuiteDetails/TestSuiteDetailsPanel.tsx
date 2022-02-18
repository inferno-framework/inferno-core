import React, { FC } from 'react';
import { TestGroup, RunnableType, TestSuite, Request, Test } from 'models/testSuiteModels';
import TestGroupListItem from './TestGroupListItem';
import TestListItem from './TestListItem/TestListItem';
import TestGroupCard from './TestGroupCard';
import TestSuiteMessages from './TestSuiteMessages';

interface TestSuiteDetailsPanelProps {
  runnable: TestSuite | TestGroup;
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  updateRequest: (requestId: string, resultId: string, request: Request) => void;
  testRunInProgresss: boolean;
}

const TestSuiteDetailsPanel: FC<TestSuiteDetailsPanelProps> = ({
  runnable,
  runTests,
  updateRequest,
  testRunInProgresss,
}) => {
  let listItems: JSX.Element[] = [];
  if (runnable?.test_groups && runnable.test_groups.length > 0) {
    listItems = runnable.test_groups.map((testGroup: TestGroup) => {
      return (
        <TestGroupListItem
          key={`li-${testGroup.id}`}
          testGroup={testGroup}
          runTests={runTests}
          testRunInProgress={testRunInProgresss}
        />
      );
    });
  } else if ('tests' in runnable) {
    listItems = runnable.tests.map((test: Test) => {
      return (
        <TestListItem
          key={`li-${test.id}`}
          test={test}
          runTests={runTests}
          updateRequest={updateRequest}
          testRunInProgress={testRunInProgresss}
        />
      );
    });
  }

  const testSuiteMessages =
    'configuration_messages' in runnable ? (
      <TestSuiteMessages messages={runnable.configuration_messages || []} />
    ) : (
      <div></div>
    );

  return (
    <div>
      {testSuiteMessages}
      <TestGroupCard runTests={runTests} runnable={runnable} testRunInProgress={testRunInProgresss}>
        {listItems}
      </TestGroupCard>
    </div>
  );
};

export default TestSuiteDetailsPanel;
