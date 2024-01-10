import React, { FC } from 'react';
// import { AppBar, Box, Drawer, Skeleton, SwipeableDrawer, Toolbar } from '@mui/material';
import { Box, Drawer, Skeleton } from '@mui/material';
import { useAppStore } from '~/store/app';
import useStyles from '~/components/TestSuite/TestSuiteTree/styles';

const DrawerSkeleton: FC<Record<string, never>> = () => {
  const { classes } = useStyles();
  // const headerHeight = useAppStore((state) => state.headerHeight);
  const windowIsSmall = useAppStore((state) => state.windowIsSmall);

  return windowIsSmall ? (
    <></>
  ) : (
    <Drawer variant="permanent" anchor="left">
      <Skeleton variant="rounded" height="40" width="100%" />

      <Box className={classes.testSuiteTreePanel}>
        <Skeleton variant="rounded" height="40" width="100%" />

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
