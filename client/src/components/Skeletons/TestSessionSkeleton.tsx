import React, { FC } from 'react';
import { Box, Card, Skeleton } from '@mui/material';
// import { AppBar, Box, Skeleton, Toolbar } from '@mui/material';
// import { useAppStore } from '~/store/app';
// import useStyles from '~/components/TestSuite/styles';

const TestSessionSkeleton: FC<Record<string, never>> = () => {
  // const { classes } = useStyles();

  return (
    <Card variant="outlined" sx={{ mb: 3 }}>
      <Skeleton variant="circular" height={32} width={32} sx={{ m: 16, mr: 1 }} />
      <Skeleton variant="rounded" height={30} width={140} />
    </Card>
  );
};

export default TestSessionSkeleton;
