import React, { FC } from 'react';
import { RunnableType, TestGroup, TestSuite } from 'models/testSuiteModels';
import { Typography, Box } from '@mui/material';
import useStyles from './styles';
import TestRunButton from '../TestRunButton/TestRunButton';
import CondensedResultIcon from './CondensedResultIcon';

export interface TreeItemLabelProps {
  runnable: TestSuite | TestGroup;
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  testRunInProgress: boolean;
}

const TreeItemLabel: FC<TreeItemLabelProps> = ({ runnable, runTests, testRunInProgress }) => {
  const styles = useStyles();

  return (
    <Box className={styles.labelRoot} data-testid={`tiLabel-${runnable.id}`}>
      <Typography className={styles.labelText} variant="body2">
        {runnable.title}
      </Typography>
      <CondensedResultIcon result={runnable.result} />
      <TestRunButton
        runnable={runnable}
        runTests={runTests}
        setIsRunning={() => {
          return;
        }}
        testRunInProgress={testRunInProgress}
      />
    </Box>
  );
};

export default TreeItemLabel;
