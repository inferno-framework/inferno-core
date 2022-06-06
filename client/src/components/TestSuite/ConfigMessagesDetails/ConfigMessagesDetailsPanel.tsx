import React, { FC } from 'react';
import { Box, Card, Chip, Divider, Tab, Tabs, Typography } from '@mui/material';
import { Message, TestSuite } from '~/models/testSuiteModels';
import useStyles from './styles';
import TabPanel from '../TestSuiteDetails/TestListItem/TabPanel';
import ReactMarkdown from 'react-markdown';
import lightTheme from 'styles/theme';

interface ConfigDetailsPanelProps {
  testSuite: TestSuite;
}

const ConfigMessagesDetailsPanel: FC<ConfigDetailsPanelProps> = ({ testSuite: runnable }) => {
  const styles = useStyles();
  const [panelIndex, setPanelIndex] = React.useState(0);

  const messages = runnable.configuration_messages || [];
  const errorMessages = messages.filter((message) => message.type === 'error');
  const warningMessages = messages.filter((message) => message.type === 'warning');
  const infoMessages = messages.filter((message) => message.type === 'info');

  const tabContent = (messages: Message[]) => (
    <Box margin={2}>
      {messages.length > 0 ? (
        messages.map((message, index) => (
          <Card key={index} variant="outlined" sx={{ padding: '0 16px', margin: '16px 0' }}>
            <ReactMarkdown>{message.message}</ReactMarkdown>
          </Card>
        ))
      ) : (
        <Typography variant="body2">No Messages</Typography>
      )}
    </Box>
  );

  const tabLabel = (label: string, count: number) => (
    <Box display="flex" alignItems="center">
      <Box px={1} sx={{ color: lightTheme.palette.common.orangeDarker }}>
        {label}
      </Box>
      {count > 0 && <Chip label={count} size="small" />}
    </Box>
  );

  const a11yProps = (id: string, index: number) => ({
    id: `${id}-tab-${index}`,
    'aria-controls': `${id}-tabpanel-${index}`,
  });

  return (
    <Card variant="outlined">
      <Box className={styles.configCardHeader}>
        <span className={styles.configCardHeaderText}>
          <Typography color="text.primary" className={styles.currentItem} component="div">
            Configuration Messages
          </Typography>
        </span>
      </Box>
      <Tabs
        aria-label="config-messages-tabs"
        value={panelIndex}
        onChange={(e, newIndex) => {
          setPanelIndex(newIndex);
        }}
        variant="fullWidth"
      >
        <Tab label={tabLabel('Errors', errorMessages.length)} {...a11yProps('errors', 0)} />
        <Tab label={tabLabel('Warnings', warningMessages.length)} {...a11yProps('warnings', 1)} />
        <Tab label={tabLabel('Info', infoMessages.length)} {...a11yProps('info', 2)} />
      </Tabs>
      <Divider />
      <TabPanel id="errors" currentPanelIndex={panelIndex} index={0}>
        {tabContent(errorMessages)}
      </TabPanel>
      <TabPanel id="warnings" currentPanelIndex={panelIndex} index={1}>
        {tabContent(warningMessages)}
      </TabPanel>
      <TabPanel id="info" currentPanelIndex={panelIndex} index={2}>
        {tabContent(infoMessages)}
      </TabPanel>
    </Card>
  );
};

export default ConfigMessagesDetailsPanel;
