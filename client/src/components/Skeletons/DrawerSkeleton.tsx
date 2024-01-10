import React, { FC } from 'react';
// import { AppBar, Box, Drawer, Skeleton, SwipeableDrawer, Toolbar } from '@mui/material';
import { Box, Drawer, Skeleton } from '@mui/material';
import { useAppStore } from '~/store/app';
import useStylesDrawer from '~/components/TestSuite/styles';
import useStylesTree from '~/components/TestSuite/TestSuiteTree/styles';

const DrawerSkeleton: FC<Record<string, never>> = () => {
  const drawerClasses = useStylesDrawer().classes;
  const treeClasses = useStylesTree().classes;
  // const headerHeight = useAppStore((state) => state.headerHeight);
  const windowIsSmall = useAppStore((state) => state.windowIsSmall);

  return windowIsSmall ? (
    <></>
  ) : (
    <Drawer variant="permanent" anchor="left" classes={{ paper: drawerClasses.drawerPaper }}>
      <Skeleton variant="rounded" height="40" width="40" />

      <Box className={treeClasses.testSuiteTreePanel}>
        <Skeleton variant="rounded" height="40" width="40" />

        {/* <TreeView
            aria-label="navigation-panel"
            defaultCollapseIcon={<ExpandMoreIcon aria-hidden={false} tabIndex={0} />}
            defaultExpandIcon={<ChevronRightIcon aria-hidden={false} tabIndex={0} />}
            onNodeToggle={nodeToggle}
            expanded={expanded}
            selected={selectedNode}
            className={classes.testSuiteTree}
          >
            <Skeleton height={20} width="60%" />

            {testGroupList}
            <CustomTreeItem
            />
            <Box display="flex" alignItems="flex-end" flexGrow={1} mt={8}>
              <Box width="100%">{renderConfigMessagesTreeItem()}</Box>
            </Box>
          </TreeView> */}
      </Box>
    </Drawer>
  );
};

export default DrawerSkeleton;
