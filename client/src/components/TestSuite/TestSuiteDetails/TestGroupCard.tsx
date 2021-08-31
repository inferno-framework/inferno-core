import React, { FC } from 'react';
import useStyles from './styles';
import { TestGroup, RunnableType, TestSuite } from 'models/testSuiteModels';
import { Card, IconButton, List } from '@material-ui/core';
import ResultIcon from './ResultIcon';
import PlayArrowIcon from '@material-ui/icons/PlayArrow';

interface TestGroupCardProps {
  runnable: TestSuite | TestGroup;
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  testRunInProgress: boolean;
}

const TestGroupCard: FC<TestGroupCardProps> = ({ runnable, runTests, children, testRunInProgress }) => {
  const styles = useStyles();

  const runnableType = 'tests' in runnable ? RunnableType.TestGroup : RunnableType.TestSuite;

  return (
    <Card className={styles.testGroupCard} variant="outlined">
      <div className={styles.testGroupCardHeader}>
        <span className={styles.testGroupCardHeaderResult}>
          <ResultIcon result={runnable.result} />
        </span>
        <span className={styles.testGroupCardHeaderText}>{runnable.title}</span>
        <IconButton
          disabled={testRunInProgress}
          edge="end"
          size="small"
          onClick={() => {
            runTests(runnableType, runnable.id);
          }}
          data-testid={`${runnable.id}-run-button`}
        >
          <PlayArrowIcon />
        </IconButton>
      </div>
      <List className={styles.testGroupCardList}>{children}</List>
    </Card>
  );
};

export default TestGroupCard;
