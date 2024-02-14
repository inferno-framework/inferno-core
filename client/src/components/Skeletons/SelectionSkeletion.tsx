import React, { FC } from 'react';
import { Box, Paper, Skeleton } from '@mui/material';
import { useAppStore } from '~/store/app';
import useStyles from '~/components/_common/SelectionPanel/styles';

const SelectionSkeleton: FC<Record<string, never>> = () => {
  const { classes } = useStyles();
  const windowIsSmall = useAppStore((state) => state.windowIsSmall);
  const optionCount = 3;

  const optionSkeleton = (
    <Skeleton
      variant="rounded"
      height={10}
      width={windowIsSmall ? 200 : 300}
      style={{ margin: '32px' }}
    />
  );

  const skeletonList = [];
  for (let index = 0; index < optionCount; index++) {
    skeletonList.push(<div key={index}>{optionSkeleton}</div>);
  }

  return (
    <Box display="flex">
      <Paper
        elevation={0}
        className={classes.optionsList}
        sx={{ width: windowIsSmall ? 'auto' : '400px', maxWidth: '400px' }}
      >
        <Box display="flex" alignItems="center" justifyContent={'center'} mx={1}>
          <Skeleton variant="rounded" height={30} width={150} style={{ marginTop: '16px' }} />
        </Box>

        <Box px={2} pb={2}>
          {skeletonList}
        </Box>

        <Box px={2}>
          <Skeleton variant="rounded" height={40} />
        </Box>
      </Paper>
    </Box>
  );
};

export default SelectionSkeleton;
