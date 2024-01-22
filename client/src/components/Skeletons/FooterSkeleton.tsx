import React, { FC } from 'react';
import { Box, Skeleton } from '@mui/material';
import { useAppStore } from '~/store/app';
import useStyles from '~/components/Footer/styles';

const FooterSkeleton: FC<Record<string, never>> = () => {
  const { classes } = useStyles();
  const footerHeight = useAppStore((state) => state.footerHeight);
  const windowIsSmall = useAppStore((state) => state.windowIsSmall);

  return (
    <footer
      className={classes.footer}
      style={{
        minHeight: `${footerHeight}px`,
        maxHeight: `${footerHeight}px`,
        backgroundColor: 'white',
      }}
    >
      <Box display="flex" flexDirection="row" justifyContent="space-between" width="100%">
        <Box display="flex" alignItems="center" px={2}>
          {windowIsSmall ? (
            <Skeleton variant="rectangular" height={22} width={80} sx={{ mr: 1 }} />
          ) : (
            <Skeleton
              variant="rectangular"
              height={40}
              width={100}
              style={{ marginRight: '16px' }}
            />
          )}
          <Box display="flex" flexDirection="column">
            {!windowIsSmall && <Skeleton height={10} width={60} />}
            <Skeleton height={20} width={100} />
          </Box>
        </Box>
        <Box display="flex" alignItems="center" pr={windowIsSmall ? 1 : 3} py={2}>
          {windowIsSmall ? (
            <Skeleton variant="circular" height={20} width={20} />
          ) : (
            <Skeleton variant="rounded" height={24} width={200} />
          )}
        </Box>
      </Box>
    </footer>
  );
};

export default FooterSkeleton;
