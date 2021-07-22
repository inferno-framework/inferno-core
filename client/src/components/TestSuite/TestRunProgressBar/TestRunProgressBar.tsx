import React, { FC } from 'react';
import { Box, CircularProgress, LinearProgress, Tooltip, Typography } from '@material-ui/core';
import AccessTimeIcon from '@material-ui/icons/AccessTime';
import DoneIcon from '@material-ui/icons/Done';
import QueueIcon from '@material-ui/icons/Queue';
import { withStyles } from '@material-ui/core/styles';

export interface TestRunProgressBarProps {
  status: string | null | undefined;
  testCount: number;
  completedCount: number;
}

const StyledProgressBar = withStyles((_theme) => ({
  root: {
    height: 8,
    backgroundColor: 'rgba(0,0,0,0)',
  },
  bar: {
    borderRadius: 4,
  },
}))(LinearProgress);

const StatusIndicator = (status: string | null | undefined) => {
  switch (status) {
    case 'running':
      return (
        <Tooltip title="Running">
          <CircularProgress size={24} />
        </Tooltip>
      );
    case 'waiting':
      return (
        <Tooltip title="Waiting">
          <AccessTimeIcon color="primary" />
        </Tooltip>
      );
    case 'queued':
      return (
        <Tooltip title="Queued">
          <QueueIcon color="primary" />
        </Tooltip>
      );
    case 'done':
      return (
        <Tooltip title="Done">
          <DoneIcon color="primary" />
        </Tooltip>
      );
    default:
      return null;
  }
};

const TestRunProgressBar: FC<TestRunProgressBarProps> = ({ status, testCount, completedCount }) => {
  const value = testCount !== 0 ? (100 * completedCount) / testCount : 0;
  const statusIndicator = StatusIndicator(status);

  return (
    <Box display="flex" alignItems="center" bgcolor="text.secondary" p="0.5em" borderRadius="0.5em">
      <Box mr={1} mt={0.3}>
        {statusIndicator}
      </Box>
      <Box minWidth={200} mr={1}>
        <StyledProgressBar variant="determinate" value={value} />
      </Box>
      <Box color="background.paper">
        <Typography variant="body1">
          {completedCount}/{testCount}
        </Typography>
      </Box>
    </Box>
  );
};

export default TestRunProgressBar;
