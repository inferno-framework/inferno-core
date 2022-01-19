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
    return <CondensedResultIcon result={runnable.result} />;
  };

  return (
    <Box className={styles.labelRoot} data-testid={`tiLabel-${runnable.id}`}>
      <Typography className={styles.labelText} variant="body2">
        {runnable.title}
      </Typography>
      {getResultIcon()}
      <TestRunButton
        runnable={runnable}
        runTests={runTests}
        testRunInProgress={testRunInProgress}
      />
    </Box>
  );
};

export default TreeItemLabel;
