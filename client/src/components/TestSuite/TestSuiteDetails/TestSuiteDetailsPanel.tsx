import React, { FC } from 'react';
import {
  TestGroup,
  RunnableType,
  TestSuite,
  Request,
  Test,
  Message,
} from '~/models/testSuiteModels';
import TestGroupListItem from './TestGroupListItem';
import TestListItem from './TestListItem/TestListItem';
import TestGroupCard from './TestGroupCard';
import TestSuiteMessages from './TestSuiteMessages';

interface TestSuiteDetailsPanelProps {
  runnable: TestSuite | TestGroup;
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  updateRequest: (requestId: string, resultId: string, request: Request) => void;
  testSuiteId?: string;
  configMessages?: Message[];
}

const TestSuiteDetailsPanel: FC<TestSuiteDetailsPanelProps> = ({
  runnable,
  runTests,
  updateRequest,
  testSuiteId,
  configMessages,
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
          view="run"
        />
      );
    });
  } else if ('tests' in runnable) {
    console.log(runnable);

    listItems = runnable.tests.map((test: Test) => {
      return (
        <TestListItem
          key={`li-${test.id}`}
          test={test}
          runTests={runTests}
          updateRequest={updateRequest}
          view="run"
        />
      );
    });
  }

  const testSuiteMessages = configMessages && (
    // limit to just error messages until more robust UI is in place
    <TestSuiteMessages
      messages={configMessages?.filter((message) => message.type === 'error') || []}
      testSuiteId={testSuiteId}
    />
  );

  return (
    <>
      {testSuiteMessages}
      <TestGroupCard runTests={runTests} runnable={runnable} view="run">
        {listItems}
      </TestGroupCard>
    </>
  );
};

export default TestSuiteDetailsPanel;
