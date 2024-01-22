import React, { FC } from 'react';
// import { AppBar, Box, Drawer, Skeleton, SwipeableDrawer, Toolbar } from '@mui/material';
import { Box, Divider, Drawer, Skeleton } from '@mui/material';
import { useAppStore } from '~/store/app';
import useStylesDrawer from '~/components/TestSuite/styles';
import useStylesTree from '~/components/TestSuite/TestSuiteTree/styles';

const DrawerSkeleton: FC<Record<string, never>> = () => {
  const drawerClasses = useStylesDrawer().classes;
  const treeClasses = useStylesTree().classes;
  // const headerHeight = useAppStore((state) => state.headerHeight);
  const windowIsSmall = useAppStore((state) => state.windowIsSmall);
  const skeletonCount = 3;

  const treeItemSkeleton = (
    <Box display="flex" flexDirection="row" alignItems="center" mx={2} my={1}>
      <Skeleton variant="circular" height="18px" width="20px" />
      <Skeleton variant="rounded" height="10px" width="100%" sx={{ ml: 1 }} />
    </Box>
  );

  const nestedTreeItemSkeleton = <Box ml={3}>{treeItemSkeleton}</Box>;

  const skeletonList = [];
  for (let index = 0; index < skeletonCount; index++) {
    skeletonList.push(
      <>
        {treeItemSkeleton}
        {nestedTreeItemSkeleton}
        {nestedTreeItemSkeleton}
      </>
    );
  }

  return windowIsSmall ? (
    <></>
  ) : (
    <Drawer variant="permanent" anchor="left" classes={{ paper: drawerClasses.drawerPaper }}>
      <Skeleton variant="rounded" height="40px" sx={{ m: 2 }} />
      <Divider />
      <Box className={treeClasses.testSuiteTreePanel} py={1}>
        {skeletonList}
      </Box>
    </Drawer>
  );
};

export default DrawerSkeleton;
