import React, { FC } from 'react';
import { Box, LinearProgress, Typography } from '@material-ui/core';

export interface TestRunProgressBarProps {
  testCount: number;
  completedCount: number;
}

const TestRunProgressBar: FC<TestRunProgressBarProps> = ({ testCount, completedCount }) => {
  const value = testCount !== 0 ? (100 * completedCount) / testCount : 0;

  return (
    <Box display="flex" alignItems="center" bgcolor="text.secondary" p="0.5em" borderRadius="0.5em">
      <Box minWidth={100} mr={1}>
        <LinearProgress variant="determinate" value={value} />
      </Box>
      <Box minWidth={35} color="background.paper">
        <Typography variant="body2">
          {completedCount}/{testCount}
        </Typography>
      </Box>
    </Box>
  );
};

export default TestRunProgressBar;
