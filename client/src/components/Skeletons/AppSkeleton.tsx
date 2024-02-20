import React, { FC } from 'react';
import { Box } from '@mui/material';
import lightTheme from '~/styles/theme';
import { useAppStore } from '~/store/app';
import useStyles from '~/components/TestSuite/styles';
import DrawerSkeleton from '~/components/Skeletons/DrawerSkeleton';
import TestSessionSkeleton from '~/components/Skeletons/TestSessionSkeleton';

const AppSkeleton: FC<Record<string, never>> = () => {
  const { classes } = useStyles();
  const windowIsSmall = useAppStore((state) => state.windowIsSmall);

  return (
    <Box className={classes.testSuiteMain} data-testid="appSkeleton">
      <DrawerSkeleton />
      <main
        style={{
          overflow: 'auto',
          width: '100%',
          backgroundColor: lightTheme.palette.common.grayLightest,
        }}
      >
        <Box className={classes.contentContainer} p={windowIsSmall ? 1 : 4}>
          <TestSessionSkeleton />
        </Box>
      </main>
    </Box>
  );
};

export default AppSkeleton;
