import React, { FC, useEffect } from 'react';
import useStyles from './styles';
import { TestGroup, RunnableType, Test, TestSuite, Request, Result } from 'models/testSuiteModels';
import { Card, CircularProgress, List } from '@mui/material';
import PendingIcon from '@mui/icons-material/Pending';
import ResultIcon from './ResultIcon';
import TestRunButton from '../TestRunButton/TestRunButton';
import TestGroupListItem from './TestGroupListItem';
import TestListItem from './TestListItem/TestListItem';

interface TestGroupCardProps {
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  updateRequest: (requestId: string, resultId: string, request: Request) => void;
  runnable: TestSuite | TestGroup;
  currentTest: Result | null;
  testRunInProgress: boolean;
}

const TestGroupCard: FC<TestGroupCardProps> = ({
  runTests,
  updateRequest,
  runnable,
  currentTest,
  testRunInProgress,
}) => {
  const styles = useStyles();
  const [isRunning, setIsRunning] = React.useState(testRunInProgress);

  let listItems: JSX.Element[] = [];
  if (runnable?.test_groups && runnable.test_groups.length > 0) {
    listItems = runnable.test_groups.map((testGroup: TestGroup) => {
      return (
        <TestGroupListItem
          key={`li-${testGroup.id}`}
          testGroup={testGroup}
          runTests={runTests}
          currentTest={currentTest}
          parentIsRunning={isRunning}
          testRunInProgress={testRunInProgress}
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
          currentTest={currentTest}
          testGroupId={runnable.id}
          testRunInProgress={testRunInProgress}
        />
      );
    });
  }

  useEffect(() => {
    if (!testRunInProgress) setIsRunning(false);
  }, [testRunInProgress]);

  const getResultIcon = () => {
    if (testRunInProgress && isRunning) {
      return <PendingIcon />;
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
      <List className={styles.testGroupCardList}>{listItems}</List>
    </Card>
  );
};

export default TestGroupCard;
