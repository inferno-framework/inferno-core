import React, { FC, useEffect } from 'react';
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
  const [isRunning, setIsRunning] = React.useState(false);

  useEffect(() => {
    if (!testRunInProgress) setIsRunning(false);
  }, [testRunInProgress]);

  const getResultIcon = () => {
    if (isRunning) {
      // If test is running and result is not from current run but is in the
      // same group, show nothing
      return <CircularProgress size={18} />;
    }
    return <ResultIcon result={runnable.result} />;
  };

  const handleSetIsRunning = (val: boolean) => {
    setIsRunning(val);
  };

  return (
    <Card className={styles.testGroupCard} variant="outlined">
      <div className={styles.testGroupCardHeader}>
        <span className={styles.testGroupCardHeaderResult}>{getResultIcon()}</span>
        <span className={styles.testGroupCardHeaderText}>{runnable.title}</span>
        <TestRunButton
          runnable={runnable}
          runTests={runTests}
          setIsRunning={handleSetIsRunning}
          testRunInProgress={testRunInProgress}
        />
      </div>
      <List className={styles.testGroupCardList}>{children}</List>
    </Card>
  );
};

export default TestGroupCard;
