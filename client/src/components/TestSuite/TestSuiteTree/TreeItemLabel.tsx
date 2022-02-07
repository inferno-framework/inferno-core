import React, { FC } from 'react';
import { TestGroup, TestSuite } from 'models/testSuiteModels';
import { Typography, Box } from '@mui/material';
import useStyles from './styles';
import CondensedResultIcon from './CondensedResultIcon';

export interface TreeItemLabelProps {
  runnable: TestSuite | TestGroup;
}

const TreeItemLabel: FC<TreeItemLabelProps> = ({ runnable }) => {
  const styles = useStyles();
  return (
    <Box className={styles.labelRoot} data-testid={`tiLabel-${runnable.id}`}>
      <Box className={styles.labelContainer}>
        <Typography className={styles.labelText} variant="body2">
          {runnable.short_title || runnable.title}
        </Typography>
        {runnable.optional && (
          <Typography className={styles.optionalLabel} variant="body2">
            Optional
          </Typography>
        )}
      </Box>
      <CondensedResultIcon result={runnable.result} />
    </Box>
  );
};

export default TreeItemLabel;
