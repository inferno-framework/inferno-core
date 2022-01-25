import React, { FC } from 'react';
import { TestGroup, RunnableType, TestSuite, Request, Test, TestRun } from 'models/testSuiteModels';
import DescriptionCard from './DescriptionCard';
import TestGroupCard from './TestGroupCard';
import TestGroupListItem from './TestGroupListItem';
import TestListItem from './TestListItem/TestListItem';

interface TestSuiteDetailsPanelProps {
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  updateRequest: (requestId: string, resultId: string, request: Request) => void;
  runnable: TestSuite | TestGroup;
  testRun: TestRun | null;
  testRunInProgress: boolean;
}

const TestSuiteDetailsPanel: FC<TestSuiteDetailsPanelProps> = ({
  runTests,
  updateRequest,
  runnable,
  testRun,
  testRunInProgress,
}) => {
  let listItems: JSX.Element[] = [];
  if (runnable?.test_groups && runnable.test_groups.length > 0) {
    listItems = runnable.test_groups.map((testGroup: TestGroup) => {
      return (
        <TestGroupListItem
          key={`li-${testGroup.id}`}
          runTests={runTests}
          testRun={testRun}
          testGroup={testGroup}
          testRunInProgress={testRunInProgress}
        />
      );
    });
  } else if ('tests' in runnable) {
    listItems = runnable.tests.map((test: Test) => {
      return (
        <TestListItem
          key={`li-${test.id}`}
          runTests={runTests}
          updateRequest={updateRequest}
          test={test}
          testRun={testRun}
          testRunInProgress={testRunInProgress}
        />
      );
    });
  }

  const descriptionCard =
    runnable.description && runnable.description.length > 0 ? (
      <DescriptionCard description={runnable.description} />
    ) : null;

  return (
    <>
      <TestGroupCard
        runTests={runTests}
        runnable={runnable}
        testRun={testRun}
        testRunInProgress={testRunInProgress}
      >
        {listItems}
      </TestGroupCard>
      {descriptionCard}
    </>
  );
};

export default TestSuiteDetailsPanel;
