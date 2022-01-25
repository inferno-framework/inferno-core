import React, { FC } from 'react';
import { TestGroup, RunnableType, TestSuite, Request, Result } from 'models/testSuiteModels';
import DescriptionCard from './DescriptionCard';
import TestGroupCard from './TestGroupCard';

interface TestSuiteDetailsPanelProps {
  runnable: TestSuite | TestGroup;
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  updateRequest: (requestId: string, resultId: string, request: Request) => void;
  currentTest: Result | null;
  testRunInProgress: boolean;
}

const TestSuiteDetailsPanel: FC<TestSuiteDetailsPanelProps> = ({
  runnable,
  runTests,
  updateRequest,
  currentTest,
  testRunInProgress,
}) => {
  const descriptionCard =
    runnable.description && runnable.description.length > 0 ? (
      <DescriptionCard description={runnable.description} />
    ) : null;

  return (
    <>
      <TestGroupCard
        runTests={runTests}
        updateRequest={updateRequest}
        runnable={runnable}
        currentTest={currentTest}
        testRunInProgress={testRunInProgress}
      />
      {descriptionCard}
    </>
  );
};

export default TestSuiteDetailsPanel;
