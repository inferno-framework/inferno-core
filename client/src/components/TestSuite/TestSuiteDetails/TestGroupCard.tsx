import React, { FC, useMemo } from 'react';
import { Box, Card, Divider, Typography } from '@mui/material';
import useStyles from './styles';
import ReactMarkdown from 'react-markdown';
import { TestGroup, RunnableType, TestSuite } from '~/models/testSuiteModels';
import InputOutputsList from './TestListItem/InputOutputsList';
import ResultIcon from './ResultIcon';
import TestRunButton from '~/components/TestSuite/TestRunButton/TestRunButton';
import { shouldShowDescription } from '~/components/TestSuite/TestSuiteUtilities';

interface TestGroupCardProps {
  runnable: TestSuite | TestGroup;
  runTests?: (runnableType: RunnableType, runnableId: string) => void;
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

  // render markdown once on mount - it's too slow with re-rendering
  const description = useMemo(() => {
    return runnable.description ? <ReactMarkdown>{runnable.description}</ReactMarkdown> : undefined;
  }, [runnable.description]);

  const runnableType = 'tests' in runnable ? RunnableType.TestGroup : RunnableType.TestSuite;

  return (
    <Card variant="outlined" sx={{ mb: 3 }}>
      <Box className={styles.testGroupCardHeader}>
        {runnable.result && <ResultIcon result={runnable.result} />}
        <span className={styles.testGroupCardHeaderText}>
          <Typography className={styles.currentItem} component="div">
            {'short_id' in runnable && (
              <Typography className={styles.shortId}>{`${runnable.short_id} `}</Typography>
            )}
            {runnable.title}
          </Typography>
        </span>
        <span className={styles.testGroupCardHeaderButton}>
          {view === 'run' && runTests && (
            <TestRunButton
              buttonText={buttonText}
              runnable={runnable}
              runnableType={runnableType}
              runTests={runTests}
              testRunInProgress={testRunInProgress}
            />
          )}
        </span>
      </Box>
      <Divider />
      {view === 'run' && shouldShowDescription(runnable, description) && (
        <>
          <Box m={2.5}>{description}</Box>
          <Divider />
        </>
      )}
      {view === 'report' &&
        runnable.run_as_group &&
        (runnable as TestGroup).user_runnable &&
        runnable.result && (
          <InputOutputsList headerName="Input" inputOutputs={runnable.result?.inputs || []} />
        )}
      <Box>{children}</Box>
    </Card>
  );
};

export default TestGroupCard;
