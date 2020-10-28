import React, { FC } from 'react';
import { Result, RunnableType } from 'models/testSuiteModels';
import { IconButton, Typography } from '@material-ui/core';
import useStyles from './styles';
import PlayArrowIcon from '@material-ui/icons/PlayArrow';
import CondensedResultIcon from './CondensedResultIcon';

export interface TreeItemLabelProps {
  title: string;
  id: string;
  result?: Result;
  runnableType: RunnableType;
  runTests: (runnableType: RunnableType, runnableId: string) => void;
}

const TreeItemLabel: FC<TreeItemLabelProps> = ({ title, id, result, runTests, runnableType }) => {
  const styles = useStyles();
  return (
    <div className={styles.labelRoot} data-testid={`tiLabel-${id}`}>
      <Typography variant="body1" className={styles.labelTitle}>
        {title}
      </Typography>
      <CondensedResultIcon result={result} />
      <IconButton
        data-testid={`runButton-${id}`}
        onClick={() => runTests(runnableType, id)}
        className={styles.labelRunButton}
      >
        <PlayArrowIcon />
      </IconButton>
    </div>
  );
};

export default TreeItemLabel;
