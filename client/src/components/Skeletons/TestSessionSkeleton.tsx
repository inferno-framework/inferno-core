import React, { FC } from 'react';
import { Box, Card, Divider, Skeleton } from '@mui/material';
import { useAppStore } from '~/store/app';
import useStyles from '~/components/TestSuite/TestSuiteDetails/styles';

const TestSessionSkeleton: FC<Record<string, never>> = () => {
  const { classes } = useStyles();
  const windowIsSmall = useAppStore((state) => state.windowIsSmall);

  const expandableItemSkeleton = (
    <>
      <Divider />
      <Box
        sx={{
          display: 'flex',
          overflow: 'auto',
          alignItems: 'center',
          minHeight: '36.5px',
          padding: '8px 16px',
        }}
      >
        <Skeleton variant="circular" height={24} width={24} />
        <span className={classes.testGroupCardHeaderText}>
          <Skeleton height={20} width={240} />
        </span>
      </Box>
    </>
  );

  return (
    <Card variant="outlined" sx={{ mb: 3 }}>
      <Box className={classes.testGroupCardHeader}>
        <Skeleton variant="circular" height={24} width={24} />
        <span className={classes.testGroupCardHeaderText}>
          <Skeleton height={20} width={240} />
        </span>
        <span className={classes.testGroupCardHeaderButton}>
          {windowIsSmall ? (
            <Skeleton variant="circular" height={24} width={24} sx={{ mr: 1 }} />
          ) : (
            <Skeleton variant="rounded" height={30} width={140} />
          )}
        </span>
      </Box>
      <Divider />
      <Box m={2.5}>
        <Skeleton height={10} width="90%" sx={{ my: 1 }} />
        <Skeleton height={10} width="95%" sx={{ my: 1 }} />
        <Skeleton height={10} sx={{ my: 1 }} />
        <Skeleton height={10} width="90%" sx={{ my: 1 }} />
        <Skeleton height={10} width="95%" sx={{ my: 1 }} />
        <Skeleton height={10} sx={{ my: 1 }} />
        <Skeleton height={10} width="50%" sx={{ my: 1 }} />
      </Box>
      {expandableItemSkeleton}
      {expandableItemSkeleton}
      {expandableItemSkeleton}
    </Card>
  );
};

export default TestSessionSkeleton;
