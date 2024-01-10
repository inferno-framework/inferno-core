import React, { FC } from 'react';
import { Box, Skeleton } from '@mui/material';
// import { AppBar, Box, Skeleton, Toolbar } from '@mui/material';
// import { useAppStore } from '~/store/app';
// import useStyles from '~/components/TestSuite/styles';

const TestSessionSkeleton: FC<Record<string, never>> = () => {
  // const { classes } = useStyles();

  return (
    <Box display="flex">
      <Skeleton variant="circular" height={32} width={32} style={{ marginRight: '8px' }} />
      <Skeleton variant="rounded" height={30} width={140} />
    </Box>
  );
};

export default TestSessionSkeleton;
