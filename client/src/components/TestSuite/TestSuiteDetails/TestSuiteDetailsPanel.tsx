import React, { FC } from 'react';
import useStyles from './styles';
import { TestGroup, RunnableType, TestSuite, Request } from 'models/testSuiteModels';
import TestSuiteDetails from './TestSuiteDetails';
import TestGroupDetails from './TestGroupDetails';

interface TestSuiteDetailsPanelProps {
  runnableType: RunnableType;
  runnable: TestSuite | TestGroup;
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  setSelectedRunnable: (id: string, type: RunnableType) => void;
  updateRequest: (requestId: string, resultId: string, request: Request) => void;
}

const TestSuiteDetailsPanel: FC<TestSuiteDetailsPanelProps> = ({
  runnableType,
  runnable,
  runTests,
  setSelectedRunnable,
  updateRequest,
}) => {
  const styles = useStyles();
  let runnableDetails: JSX.Element;
  if (runnableType == RunnableType.TestSuite) {
    runnableDetails = (
      <TestSuiteDetails
        {...(runnable as TestSuite)}
        runTests={runTests}
        setSelectedRunnable={setSelectedRunnable}
        updateRequest={updateRequest}
      />
    );
  } else {
    runnableDetails = (
      <TestGroupDetails
        {...(runnable as TestGroup)}
        runTests={runTests}
        setSelectedRunnable={setSelectedRunnable}
        updateRequest={updateRequest}
      />
    );
  }
  return <div className={styles.testSuiteDetailsPanel}>{runnableDetails}</div>;
};

export default TestSuiteDetailsPanel;
