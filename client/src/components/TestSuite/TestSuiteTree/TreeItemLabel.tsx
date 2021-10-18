import React, { FC } from 'react';
import { RunnableType, TestGroup, TestSuite } from 'models/testSuiteModels';
import { Typography } from '@material-ui/core';
import useStyles from './styles';
import CondensedResultIcon from './CondensedResultIcon';
import TestRunButton from '../TestRunButton/TestRunButton';

export interface TreeItemLabelProps {
  runnable: TestSuite | TestGroup;
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  testRunInProgress: boolean;
}

const TreeItemLabel: FC<TreeItemLabelProps> = ({ runnable, runTests, testRunInProgress }) => {
  const styles = useStyles();
  return (
    <div className={styles.labelRoot} data-testid={`tiLabel-${runnable.id}`}>
      <Typography className={styles.labelText} variant="body2">
        {runnable.title}
      </Typography>
      <CondensedResultIcon result={runnable.result} />
      <TestRunButton
        runnable={runnable}
        runTests={runTests}
        testRunInProgress={testRunInProgress}
      />
    </div>
  );
};

export default TreeItemLabel;
