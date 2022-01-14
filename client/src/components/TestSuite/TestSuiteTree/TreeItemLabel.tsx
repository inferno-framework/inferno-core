import React, { FC } from 'react';
import { Result, RunnableType, TestGroup, TestSuite } from 'models/testSuiteModels';
import { CircularProgress, Typography, Box } from '@mui/material';
import useStyles from './styles';
import CondensedResultIcon from './CondensedResultIcon';
import TestRunButton from '../TestRunButton/TestRunButton';

export interface TreeItemLabelProps {
  runnable: TestSuite | TestGroup;
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  currentTest: Result | null;
  testRunInProgress: boolean;
}

const TreeItemLabel: FC<TreeItemLabelProps> = ({
  runnable,
  runTests,
  currentTest,
  testRunInProgress,
}) => {
  const styles = useStyles();

  return (
    <Box className={styles.labelRoot} data-testid={`tiLabel-${runnable.id}`}>
      <Typography className={styles.labelText} variant="body2">
        {runnable.title}
      </Typography>
      {testRunInProgress && currentTest && currentTest.test_id?.includes(runnable.id) ? (
        <CircularProgress size={12} />
      ) : (
        <CondensedResultIcon result={runnable.result} />
      )}
      <TestRunButton
        runnable={runnable}
        runTests={runTests}
        testRunInProgress={testRunInProgress}
      />
    </Box>
  );
};

export default TreeItemLabel;
