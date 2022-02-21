import React, { FC } from 'react';
import useStyles from './styles';
import { TestGroup, RunnableType, TestSuite } from 'models/testSuiteModels';
import { Box, Card, Divider, List, Typography } from '@mui/material';
import ReactMarkdown from 'react-markdown';
import ResultIcon from './ResultIcon';
import TestRunButton from '../TestRunButton/TestRunButton';

interface TestGroupCardProps {
  runnable: TestSuite | TestGroup;
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  testRunInProgress: boolean;
  view: 'report' | 'run';
}

const TestGroupCard: FC<TestGroupCardProps> = ({
  runnable,
  runTests,
  children,
  testRunInProgress,
  view,
}) => {
  const styles = useStyles();

  const buttonText = runnable.run_as_group ? 'Run Tests' : 'Run All Tests';

  const description = view == 'run' && runnable.description && runnable.description.length > 0 && (
    <ReactMarkdown>{runnable.description}</ReactMarkdown>
  );

  const resultSpan = runnable.result && (
    <span className={styles.testIcon}>
      <ResultIcon result={runnable.result} />
    </span>
  );

  const runnableType = 'tests' in runnable ? RunnableType.TestGroup : RunnableType.TestSuite;

  return (
    <Card className={styles.testGroupCard} variant="outlined">
      <div className={styles.testGroupCardHeader}>
        {resultSpan}
        <span className={styles.testGroupCardHeaderText}>
          <Typography key="1" color="text.primary" className={styles.currentItem}>
            {runnable.title}
          </Typography>
        </span>
        <span className={styles.testGroupCardHeaderButton}>
          {view === 'run' && (
          <TestRunButton
            buttonText={buttonText}
            runnable={runnable}
            runnableType={runnableType}
            runTests={runTests}
            testRunInProgress={testRunInProgress}
          />
          )}
        </span>
      </div>
      {view == 'run' && description && (
        <>
          <Box margin="20px">{description}</Box>
          <Divider />
        </>
      )}
      <List className={styles.testGroupCardList}>{children}</List>
    </Card>
  );
};

export default TestGroupCard;
