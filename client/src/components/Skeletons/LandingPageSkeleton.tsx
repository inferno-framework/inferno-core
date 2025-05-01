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
    <Container maxWidth={false} className={classes.main} data-testid="landingPageSkeleton">
      <Box
        display="flex"
        flexDirection="column"
        justifyContent={windowIsSmall ? 'center' : 'flex-end'}
        alignItems="center"
        px={2}
      >
        <Box
          display="flex"
          flexDirection="column"
          my={2}
          alignItems="center"
          justifyContent="center"
        >
          <Skeleton variant="rounded" height={70} width={250} style={{ margin: '32px' }} />
          <Skeleton
            variant="rounded"
            height={40}
            width={windowIsSmall ? 200 : 400}
            style={{ margin: '8px' }}
          />
        </Box>
        <Box mb={2} alignItems="center">
          <Skeleton
            variant="rounded"
            height={20}
            width={windowIsSmall ? 250 : 500}
            style={{ margin: '8px' }}
          />
          <Skeleton
            variant="rounded"
            height={20}
            width={windowIsSmall ? 250 : 500}
            style={{ margin: '8px' }}
          />
        </Box>
      </Box>
      <Box
        display="flex"
        flexDirection="column"
        alignItems="center"
        width="100%"
        py={4}
        sx={{ backgroundColor: lightTheme.palette.common.grayLight }}
      >
        <SelectionSkeleton />
      </Box>
    </Container>
  );
};

export default LandingPageSkeleton;
