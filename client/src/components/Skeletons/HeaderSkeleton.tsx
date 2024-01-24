import React, { FC } from 'react';
import { AppBar, Box, Skeleton, Toolbar } from '@mui/material';
import { useAppStore } from '~/store/app';
import useStyles from '~/components/Header/styles';

const HeaderSkeleton: FC<Record<string, never>> = () => {
  const { classes } = useStyles();
  const headerHeight = useAppStore((state) => state.headerHeight);
  const windowIsSmall = useAppStore((state) => state.windowIsSmall);

  return (
    <AppBar
      color="default"
      className={classes.appbar}
      style={{
        minHeight: `${headerHeight}px`, // For responsive screens
        maxHeight: `${headerHeight}px`, // For responsive screens
      }}
    >
      <Toolbar className={classes.toolbar}>
        {/* Home button */}
        <Skeleton variant="circular" height={44} width={44} />

        {/* Header Text */}
        <Box display="flex" flexDirection="column" flexGrow="1" alignSelf="center" py={0.5} pl={2}>
          <Skeleton height={35} width="70%" />
          <Skeleton height={15} width="60%" />
        </Box>

        {/* New Session button */}
        <Box display="flex" style={windowIsSmall ? { marginRight: '-16px' } : {}}>
          {windowIsSmall ? (
            <Skeleton variant="circular" height={32} width={32} sx={{ mr: 1 }} />
          ) : (
            <Skeleton variant="rounded" height={30} width={140} />
          )}
        </Box>
      </Toolbar>
    </AppBar>
  );
};

export default HeaderSkeleton;
