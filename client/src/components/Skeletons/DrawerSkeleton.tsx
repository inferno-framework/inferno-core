import React, { FC } from 'react';
import { Box, Divider, Drawer, Skeleton } from '@mui/material';
import { useAppStore } from '~/store/app';
import useStylesDrawer from '~/components/TestSuite/styles';
import useStylesTree from '~/components/TestSuite/TestSuiteTree/styles';

const DrawerSkeleton: FC<Record<string, never>> = () => {
  const drawerClasses = useStylesDrawer().classes;
  const treeClasses = useStylesTree().classes;
  const windowIsSmall = useAppStore((state) => state.windowIsSmall);
  const skeletonCount = 3;

  const treeItemSkeleton = (
    <Box display="flex" flexDirection="row" alignItems="center" mx={2} my={2}>
      <Skeleton variant="circular" height="14px" width="16px" />
      <Skeleton height={10} width={200} sx={{ ml: 1 }} />
    </Box>
  );

  const nestedTreeItemSkeleton = <Box ml={3}>{treeItemSkeleton}</Box>;

  const skeletonList = [];
  for (let index = 0; index < skeletonCount; index++) {
    skeletonList.push(
      <div key={index}>
        {treeItemSkeleton}
        {nestedTreeItemSkeleton}
        {nestedTreeItemSkeleton}
      </div>
    );
  }

  return windowIsSmall ? (
    <></>
  ) : (
    <Drawer
      variant="permanent"
      anchor="left"
      classes={{ paper: drawerClasses.drawerPaper }}
      data-testid="drawerSkeleton"
    >
      <Skeleton variant="rounded" height={32} sx={{ m: 2 }} />
      <Divider />
      <Box className={treeClasses.testSuiteTreePanel} py={1}>
        {skeletonList}
      </Box>
    </Drawer>
  );
};

export default DrawerSkeleton;
