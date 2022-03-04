import React, { FC } from 'react';
import { TestGroup, TestSuite } from 'models/testSuiteModels';
import { Typography, Box } from '@mui/material';
import useStyles from './styles';

export interface TreeItemLabelProps {
  runnable?: TestSuite | TestGroup;
  title?: string;
}

const TreeItemLabel: FC<TreeItemLabelProps> = ({ runnable, title }) => {
  const styles = useStyles();
  return (
    <Box className={styles.labelRoot} data-testid={`tiLabel-${runnable?.id as string}`}>
      <Box className={styles.labelContainer}>
        {runnable && 'short_id' in runnable && (
          <Typography className={styles.shortId} variant="body2">
            {runnable.short_id}
          </Typography>
        )}
        <Typography className={styles.labelText} variant="body2">
          {title || runnable?.short_title || runnable?.title}
        </Typography>
        {runnable?.optional && (
          <Typography className={styles.optionalLabel} variant="body2">
            Optional
          </Typography>
        )}
      </Box>
    </Box>
  );
};

export default TreeItemLabel;
