import React, { FC } from 'react';
import { Box } from '@mui/material';
import { lighten } from '@mui/material/styles';
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
          backgroundColor: lighten(lightTheme.palette.common.grayLight, 0.5),
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
