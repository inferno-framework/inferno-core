import React, { FC } from 'react';
import { AppBar, Box, Drawer, Skeleton, SwipeableDrawer, Toolbar } from '@mui/material';
import { useAppStore } from '~/store/app';
import useStyles from '~/components/Header/styles';

const DrawerSkeleton: FC<Record<string, never>> = () => {
  const { classes } = useStyles();
  const headerHeight = useAppStore((state) => state.headerHeight);
  const windowIsSmall = useAppStore((state) => state.windowIsSmall);

  return windowIsSmall ? (
    <></>
  ) : (
    <Drawer variant="permanent" anchor="left">
      <nav style={{ display: 'flex', flexGrow: 1 }}>
        <TestSuiteTreeComponent
          testSuite={testSession.test_suite}
          selectedRunnable={selectedRunnable}
          view={view || 'run'}
          presets={testSession.test_suite.presets}
          getSessionData={getSessionData}
          testSessionId={testSession.id}
        />
      </nav>
    </Drawer>
  );
};

export default DrawerSkeleton;
