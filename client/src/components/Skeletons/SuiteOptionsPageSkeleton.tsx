import React, { FC } from 'react';
import { Box, Container, Skeleton } from '@mui/material';
import { useAppStore } from '~/store/app';
import SelectionSkeleton from '~/components/Skeletons/SelectionSkeletion';
import useStyles from '~/components/SuiteOptionsPage/styles';
import lightTheme from '~/styles/theme';

const SuiteOptionsPageSkeleton: FC<Record<string, never>> = () => {
  const { classes } = useStyles();
  const windowIsSmall = useAppStore((state) => state.windowIsSmall);
  const textLineCount = 10;

  const textLineSkeleton = (
    <Skeleton
      variant="rounded"
      height={10}
      width={windowIsSmall ? 300 : 400}
      style={{ margin: '8px' }}
    />
  );

  const skeletonList = [];
  for (let index = 0; index < textLineCount; index++) {
    skeletonList.push(<div key={index}>{textLineSkeleton}</div>);
  }

  return (
    <Container className={classes.main} sx={{ flexDirection: windowIsSmall ? '' : 'column' }}>
      <Box
        display="flex"
        flexDirection="column"
        justifyContent="center"
        alignItems="center"
        px={windowIsSmall ? 0 : 8}
        my={3}
      >
        <Box display="flex" alignItems="center" m={4}>
          <Skeleton variant="rounded" height={40} width={windowIsSmall ? 200 : 350} />
        </Box>
        <Box display="flex" flexDirection="column" justifyContent="center" px={2} mb={3}>
          {skeletonList}
        </Box>
      </Box>
      <Box
        display="flex"
        height={windowIsSmall ? 'none' : '100%'}
        width={windowIsSmall ? '100%' : 'none'}
        justifyContent="center"
        alignItems="center"
        sx={{ backgroundColor: lightTheme.palette.common.grayLightest }}
      >
        <Box display="flex" justifyContent="center" m={3}>
          <SelectionSkeleton />
        </Box>
      </Box>
    </Container>
  );
};

export default SuiteOptionsPageSkeleton;
