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
  user_runnable?: boolean;
}

const TreeItemLabel: FC<TreeItemLabelProps> = ({
  title,
  id,
  result,
  runTests,
  runnableType,
  testRunInProgress,
  user_runnable
}) => {
  const styles = useStyles();
  return (
    <div className={styles.labelRoot} data-testid={`tiLabel-${id}`}>
      <Typography className={styles.labelText} variant="body2">
        {title}
      </Typography>
      <CondensedResultIcon result={result} />
      {user_runnable ? (
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
      ) : null}
    </div>
  );
};

export default TreeItemLabel;
