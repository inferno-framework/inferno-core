import React, { FC } from 'react';
import useStyles from './styles';
import { TestGroup, RunnableType, TestSuite, Result } from 'models/testSuiteModels';
import { Card, CircularProgress, List } from '@mui/material';
import ResultIcon from './ResultIcon';
import TestRunButton from '../TestRunButton/TestRunButton';

interface TestGroupCardProps {
  runnable: TestSuite | TestGroup;
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  currentTest: Result | null;
  testRunInProgress: boolean;
}

const TestGroupCard: FC<TestGroupCardProps> = ({
  runnable,
  runTests,
  children,
  currentTest,
  testRunInProgress,
}) => {
  const styles = useStyles();

  const checkIfSameGroup = (test: Result | null, testCollection: TestSuite | TestGroup) => {
    let isSameGroup = false;
    // Check if testCollection is a TestGroup
    if ('tests' in testCollection) {
      isSameGroup = testCollection.tests.some((t) => t.id === test?.test_id);
    } else {
      if (testCollection.test_groups) {
        isSameGroup = testCollection.test_groups.some((group) =>
          group.tests.some((t) => t.id === test?.test_id)
        );
      }
    }
    return isSameGroup;
  };

  const getResultIcon = () => {
    if (testRunInProgress && currentTest?.test_id?.includes(runnable?.id)) {
      return <CircularProgress size={18} />;
    } else if (
      testRunInProgress &&
      currentTest?.test_run_id !== runnable?.result?.test_run_id &&
      checkIfSameGroup(currentTest, runnable)
    ) {
      // If test is running and result is not from current run but is in the
      // same group, show nothing
      return null;
    }
    return <ResultIcon result={runnable.result} />;
  };

  return (
    <Card className={styles.testGroupCard} variant="outlined">
      <div className={styles.testGroupCardHeader}>
        <span className={styles.testGroupCardHeaderResult}>{getResultIcon()}</span>
        <span className={styles.testGroupCardHeaderText}>{runnable.title}</span>
        <TestRunButton
          runnable={runnable}
          runTests={runTests}
          testRunInProgress={testRunInProgress}
        />
      </div>
      <List className={styles.testGroupCardList}>{children}</List>
    </Card>
  );
};

export default TestGroupCard;
