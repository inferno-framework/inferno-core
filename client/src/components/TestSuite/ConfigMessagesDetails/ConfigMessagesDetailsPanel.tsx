import React, { FC } from 'react';
import { Box, Card, Typography } from '@mui/material';
import { TestGroup, TestSuite } from 'models/testSuiteModels';
import TestSuiteMessages from '../TestSuiteDetails/TestSuiteMessages';
import useStyles from './styles';

interface ConfigDetailsPanelProps {
  runnable: TestSuite | TestGroup;
}

const ConfigMessagesDetailsPanel: FC<ConfigDetailsPanelProps> = ({ runnable }) => {
  const styles = useStyles();

  const testSuiteMessages = 'configuration_messages' in runnable && (
    <TestSuiteMessages messages={runnable.configuration_messages || []} view="config" />
  );

  return (
    <Card variant="outlined">
      <Box className={styles.configCardHeader}>
        <span className={styles.configCardHeaderText}>
          <Typography color="text.primary" className={styles.currentItem} component="div">
            Configuration Messages
          </Typography>
        </span>
      </Box>
      <Box margin="20px">{testSuiteMessages}</Box>
    </Card>
  );
};

export default ConfigMessagesDetailsPanel;
