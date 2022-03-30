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
  testRunInProgress: boolean;
}

const TestSuiteDetailsPanel: FC<TestSuiteDetailsPanelProps> = ({
  runnable,
  runTests,
  updateRequest,
  testRunInProgress,
}) => {
  let listItems: JSX.Element[] = [];
  if (runnable?.test_groups && runnable.test_groups.length > 0) {
    listItems = runnable.test_groups.map((testGroup: TestGroup) => {
      return (
        <TestGroupListItem
          key={`li-${testGroup.id}`}
          testGroup={testGroup}
          runTests={runTests}
          updateRequest={updateRequest}
          testRunInProgress={testRunInProgress}
          view="run"
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
          testRunInProgress={testRunInProgress}
          view="run"
        />
      );
    });
  }

  const testSuiteMessages = 'configuration_messages' in runnable && (
    // limit to just error messages until more robust UI is in place
    <TestSuiteMessages
      messages={
        runnable.configuration_messages?.filter((message) => message.type === 'error') || []
      }
      view="run"
    />
  );

  return (
    <>
      {testSuiteMessages}
      <TestGroupCard
        runTests={runTests}
        runnable={runnable}
        testRunInProgress={testRunInProgress}
        view="run"
      >
        {listItems}
      </TestGroupCard>
    </>
  );
};

export default TestSuiteDetailsPanel;
