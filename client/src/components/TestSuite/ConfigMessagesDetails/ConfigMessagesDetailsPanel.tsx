import React, { FC } from 'react';
import { Box, Card, Typography } from '@mui/material';
import { TestSuite } from 'models/testSuiteModels';
import TestSuiteMessages from '../TestSuiteDetails/TestSuiteMessages';
import useStyles from './styles';

interface ConfigDetailsPanelProps {
  testSuite: TestSuite;
}

const ConfigMessagesDetailsPanel: FC<ConfigDetailsPanelProps> = ({ testSuite: runnable }) => {
  const styles = useStyles();

  const testSuiteMessages = (
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
