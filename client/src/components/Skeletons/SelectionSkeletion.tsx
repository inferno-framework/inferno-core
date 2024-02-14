import React, { FC } from 'react';
import { Box, Paper, Skeleton } from '@mui/material';
import { useAppStore } from '~/store/app';
import useStyles from '~/components/_common/SelectionPanel/styles';

const SelectionSkeleton: FC<Record<string, never>> = () => {
  const { classes } = useStyles();
  const windowIsSmall = useAppStore((state) => state.windowIsSmall);

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
          <Skeleton variant="rounded" height={10} width={300} style={{ margin: '32px' }} />
          <Skeleton variant="rounded" height={10} width={300} style={{ margin: '32px' }} />
          <Skeleton variant="rounded" height={10} width={300} style={{ margin: '32px' }} />
        </Box>

        <Box px={2}>
          <Skeleton variant="rounded" height={40} />
        </Box>
      </Paper>
    </Box>
  );
};

export default SelectionSkeleton;
