import React, { FC } from 'react';
import { Box, Card, Divider, Skeleton } from '@mui/material';
import { useAppStore } from '~/store/app';
import useStyles from '~/components/TestSuite/TestSuiteDetails/styles';

const TestSessionSkeleton: FC<Record<string, never>> = () => {
  const { classes } = useStyles();
  const windowIsSmall = useAppStore((state) => state.windowIsSmall);
  const skeletonCount = 3;

  const expandableItemSkeleton = (
    <>
      <Divider />
      <Box
        sx={{
          display: 'flex',
          alignItems: 'center',
          minHeight: '36.5px',
          px: 2,
          py: 1,
        }}
      >
        <Skeleton variant="circular" height={24} width={24} />
        <span className={classes.testGroupCardHeaderText}>
          <Skeleton height={20} width={240} />
        </span>
      </Box>
    </>
  );

  const skeletonList = [];
  for (let index = 0; index < skeletonCount; index++) {
    skeletonList.push(<div key={index}>{expandableItemSkeleton}</div>);
  }

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
        <Skeleton height={10} sx={{ my: 2 }} />
        <Skeleton height={10} width="90%" sx={{ my: 2 }} />
        <Skeleton height={10} width="95%" sx={{ my: 2 }} />
        <Skeleton height={10} sx={{ my: 2 }} />
        <Skeleton height={10} width="90%" sx={{ my: 2 }} />
        <Skeleton height={10} width="95%" sx={{ my: 2 }} />
        <Skeleton height={10} width="50%" sx={{ my: 2 }} />
      </Box>
      {skeletonList}
    </Card>
  );
};

export default TestSessionSkeleton;
