import React, { FC } from 'react';
import { Box, Card, Divider, Typography } from '@mui/material';
import { TestGroup, TestSuite } from 'models/testSuiteModels';
import TestSuiteMessages from './../TestSuiteDetails/TestSuiteMessages';
import useStyles from './styles';

interface ConfigDetailsPanelProps {
  runnable: TestSuite | TestGroup;
}

const ConfigDetailsPanel: FC<ConfigDetailsPanelProps> = ({ runnable }) => {
  const styles = useStyles();

  const testSuiteMessages = 'configuration_messages' in runnable && (
    // limit to just error messages until more robust UI is in place
    <TestSuiteMessages messages={runnable.configuration_messages || []} />
  );

  return (
    <Card>
      <div className={styles.configCardHeader}>
        <span className={styles.configCardHeaderText}>
          <Typography color="text.primary" className={styles.currentItem} component="div">
            Configuration Messages
          </Typography>
        </span>
      </div>
      <Box margin="20px"> {testSuiteMessages}</Box>
    </Card>
  );
};

export default ConfigDetailsPanel;
