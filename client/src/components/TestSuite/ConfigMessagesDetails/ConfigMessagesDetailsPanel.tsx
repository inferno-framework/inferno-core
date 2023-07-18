import React, { FC } from 'react';
import { Box, Card, Chip, Divider, Tab, Tabs, Typography } from '@mui/material';
import { Message, TestSuite } from '~/models/testSuiteModels';
import useStyles from './styles';
import TabPanel from '../TestSuiteDetails/TestListItem/TabPanel';
import ReactMarkdown from 'react-markdown';

interface ConfigDetailsPanelProps {
  testSuite: TestSuite;
}

const ConfigMessagesDetailsPanel: FC<ConfigDetailsPanelProps> = ({ testSuite: runnable }) => {
  const { classes } = useStyles();
  const [tabIndex, setTabIndex] = React.useState(0);

  const messages = runnable.configuration_messages || [];
  const errorMessages = messages.filter((message) => message.type === 'error');
  const warningMessages = messages.filter((message) => message.type === 'warning');
  const infoMessages = messages.filter((message) => message.type === 'info');

  const tabContent = (messages: Message[]) => (
    <Box margin={2}>
      {messages.length > 0 ? (
        messages.map((message, index) => (
          <Card key={index} variant="outlined" sx={{ px: 2, my: 2, overflow: 'auto' }}>
            <ReactMarkdown>{message.message}</ReactMarkdown>
          </Card>
        ))
      ) : (
        <Typography variant="body2">No Messages</Typography>
      )}
    </Box>
  );

  const tabLabel = (label: string, count: number) => (
    <Box alignItems="center">
      <Box px={1}>{label}</Box>
      {count > 0 && <Chip label={count} size="small" style={{ margin: '4px' }} />}
    </Box>
  );

  const a11yProps = (id: string, index: number) => ({
    id: `${id}-tab-${index}`,
    'aria-controls': `${id}-tabpanel-${index}`,
  });

  return (
    <Card variant="outlined">
      <Box className={classes.configCardHeader}>
        <span className={classes.configCardHeaderText}>
          <Typography color="text.primary" className={classes.currentItem} component="div">
            Configuration Messages
          </Typography>
        </span>
      </Box>
      <Tabs
        aria-label="config-messages-tabs"
        value={tabIndex}
        onChange={(e, newIndex: number) => {
          setTabIndex(newIndex);
        }}
        variant="fullWidth"
      >
        <Tab
          label={tabLabel('Errors', errorMessages.length)}
          {...a11yProps('errors', 0)}
          classes={{ root: classes.tab, selected: classes.tab }}
        />
        <Tab
          label={tabLabel('Warnings', warningMessages.length)}
          {...a11yProps('warnings', 1)}
          classes={{ root: classes.tab, selected: classes.tab }}
        />
        <Tab
          label={tabLabel('Info', infoMessages.length)}
          {...a11yProps('info', 2)}
          classes={{ root: classes.tab, selected: classes.tab }}
        />
      </Tabs>
      <Divider />
      <TabPanel id="errors" currentTabIndex={tabIndex} index={0}>
        {tabContent(errorMessages)}
      </TabPanel>
      <TabPanel id="warnings" currentTabIndex={tabIndex} index={1}>
        {tabContent(warningMessages)}
      </TabPanel>
      <TabPanel id="info" currentTabIndex={tabIndex} index={2}>
        {tabContent(infoMessages)}
      </TabPanel>
    </Card>
  );
};

export default ConfigMessagesDetailsPanel;
