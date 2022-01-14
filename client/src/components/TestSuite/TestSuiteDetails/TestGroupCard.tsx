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

  return (
    <Card className={styles.testGroupCard} variant="outlined">
      <div className={styles.testGroupCardHeader}>
        <span className={styles.testGroupCardHeaderResult}>
          {testRunInProgress &&
          currentTest?.test_id?.includes(runnable?.result?.test_group_id as string) ? (
            <CircularProgress size={18} />
          ) : (
            <ResultIcon result={runnable.result} />
          )}
        </span>
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
