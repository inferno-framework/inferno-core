import React, { FC } from 'react';
import useStyles from './styles';
import { TestGroup, RunnableType, TestSuite, TestRun } from 'models/testSuiteModels';
import { Card, List } from '@mui/material';
import PendingIcon from '@mui/icons-material/Pending';
import ResultIcon from './ResultIcon';
import TestRunButton from '../TestRunButton/TestRunButton';

interface TestGroupCardProps {
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  runnable: TestSuite | TestGroup;
  testRun: TestRun | null;
  testRunInProgress: boolean;
}

const TestGroupCard: FC<TestGroupCardProps> = ({
  runTests,
  runnable,
  testRun,
  testRunInProgress,
  children,
}) => {
  const styles = useStyles();

  const getResultIcon = () => {
    if (testRunInProgress && testRun?.test_group_id === runnable.id) {
      return <PendingIcon color="disabled" />;
    }
    return <ResultIcon result={runnable.result} />;
  };

  return (
    <Card className={styles.testGroupCard} variant="outlined">
      <div className={styles.testGroupCardHeader}>
        <span className={styles.testGroupCardHeaderResult}>{getResultIcon()}</span>
        <span className={styles.testGroupCardHeaderText}>{runnable.title}</span>
        <TestRunButton
          runTests={runTests}
          runnable={runnable}
          testRunInProgress={testRunInProgress}
        />
      </div>
      <List className={styles.testGroupCardList}>{children}</List>
    </Card>
  );
};

export default TestGroupCard;
