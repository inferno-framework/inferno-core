import React, { FC } from 'react';
import { Result, RunnableType } from 'models/testSuiteModels';
import { IconButton, Typography, Tooltip } from '@material-ui/core';
import useStyles from './styles';
import PlayArrowIcon from '@material-ui/icons/PlayArrow';
import CondensedResultIcon from './CondensedResultIcon';

export interface TreeItemLabelProps {
  title: string;
  id: string;
  result?: Result;
  runnableType: RunnableType;
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  testRunInProgress: boolean;
}

const TreeItemLabel: FC<TreeItemLabelProps> = ({
  title,
  id,
  result,
  runTests,
  runnableType,
  testRunInProgress,
}) => {
  const styles = useStyles();
  return (
    <div className={styles.labelRoot} data-testid={`tiLabel-${id}`}>
      <Typography className={styles.labelText} variant="body2">
        {title}
      </Typography>
      <CondensedResultIcon result={result} />
      <Tooltip title={testRunInProgress ? 'Disabled - Ongoing Test.' : ''} arrow>
        <div className={styles.buttonWrapper}>
          <IconButton
            disabled={testRunInProgress}
            data-testid={`runButton-${id}`}
            onClick={() => runTests(runnableType, id)}
            className={styles.labelRunButton}
          >
            <PlayArrowIcon />
          </IconButton>
        </div>
      </Tooltip>
    </div>
  );
};

export default TreeItemLabel;
