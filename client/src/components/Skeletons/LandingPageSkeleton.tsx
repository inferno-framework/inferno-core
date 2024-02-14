import React, { FC } from 'react';
import { Box, Container, Skeleton } from '@mui/material';
import { useAppStore } from '~/store/app';
import SelectionSkeleton from '~/components/Skeletons/SelectionSkeletion';
import useStyles from '~/components/LandingPage/styles';
import lightTheme from '~/styles/theme';

const LandingPageSkeleton: FC<Record<string, never>> = () => {
  const { classes } = useStyles();
  const windowIsSmall = useAppStore((state) => state.windowIsSmall);

  return (
    <Container
      maxWidth={false}
      role="main"
      className={classes.main}
      sx={
        windowIsSmall
          ? {}
          : {
              minHeight: '400px',
              maxHeight: '100vh',
              py: 10,
            }
      }
    >
      <Box
        display="flex"
        flexDirection="column"
        justifyContent={windowIsSmall ? 'center' : 'flex-end'}
        alignItems="center"
        overflow="initial"
        minHeight="300px"
        pb={windowIsSmall ? 0 : 2}
        px={2}
      >
        <Box my={2} alignItems="center" maxWidth="800px">
          <Box display="flex" alignItems="center" justifyContent="center">
            <Skeleton variant="rounded" height={70} width={300} style={{ margin: '32px' }} />
          </Box>
          <Skeleton variant="rounded" height={40} width={400} style={{ margin: '8px' }} />
        </Box>
        <Box mb={2} alignItems="center" maxWidth="600px">
          <Skeleton variant="rounded" height={20} width={500} style={{ margin: '8px' }} />
          <Skeleton variant="rounded" height={20} width={500} style={{ margin: '8px' }} />
        </Box>
      </Box>
      <Box
        display="flex"
        flexDirection="column"
        justifyContent="flex-start"
        alignItems="center"
        width="100%"
        minHeight="200px"
        py={4}
        sx={{ backgroundColor: lightTheme.palette.common.grayLightest }}
      >
        <SelectionSkeleton />
      </Box>
    </Container>
  );
};

export default LandingPageSkeleton;
