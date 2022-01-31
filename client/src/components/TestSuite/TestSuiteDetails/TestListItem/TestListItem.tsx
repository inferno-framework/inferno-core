import React, { FC } from 'react';
import useStyles from './styles';
import {
  Box,
  Collapse,
  Container,
  Divider,
  IconButton,
  ListItem,
  ListItemText,
  Tab,
  Tabs,
  Tooltip,
  Badge,
  Typography,
} from '@mui/material';
import PendingIcon from '@mui/icons-material/Pending';
import { RunnableType, Test, Request, TestRun } from 'models/testSuiteModels';
import TabPanel from './TabPanel';
import MessagesList from './MessagesList';
import RequestsList from './RequestsList';
import ResultIcon from '../ResultIcon';
import PublicIcon from '@mui/icons-material/Public';
import MailIcon from '@mui/icons-material/Mail';
import ExpandLessIcon from '@mui/icons-material/ExpandLess';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import ReactMarkdown from 'react-markdown';
import TestRunButton from '../../TestRunButton/TestRunButton';

interface TestListItemProps {
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  updateRequest: (requestId: string, resultId: string, request: Request) => void;
  test: Test;
  testRun: TestRun | null;
  testRunInProgress: boolean;
}

const TestListItem: FC<TestListItemProps> = ({
  runTests,
  updateRequest,
  test,
  testRun,
  testRunInProgress,
}) => {
  const styles = useStyles();

  const [open, setOpen] = React.useState(false);
  const [panelIndex, setPanelIndex] = React.useState(0);

  const messagesBadge = test.result?.messages && test.result.messages.length > 0 && (
    <IconButton
      className={styles.badgeIcon}
      onClick={() => {
        setPanelIndex(1);
        setOpen(true);
      }}
    >
      <Badge badgeContent={test.result.messages.length} classes={{ badge: styles.testBadge }}>
        <Tooltip title={`${test.result.messages.length} messages`}>
          <MailIcon color="secondary" />
        </Tooltip>
      </Badge>
    </IconButton>
  );

  const requestsBadge = test.result?.requests && test.result.requests.length > 0 && (
    <IconButton
      className={styles.badgeIcon}
      onClick={() => {
        setPanelIndex(2);
        setOpen(true);
      }}
    >
      <Badge badgeContent={test.result.requests.length} classes={{ badge: styles.testBadge }}>
        <Tooltip title={`${test.result.requests.length} requests`}>
          <PublicIcon color="secondary" />
        </Tooltip>
      </Badge>
    </IconButton>
  );

  const expandButton = (
    <IconButton onClick={() => setOpen(open)} size="small">
      {open ? <ExpandLessIcon /> : <ExpandMoreIcon />}
    </IconButton>
  );

  const testLabel = (
    <>
      {test.optional && <Typography className={styles.optionalLabel}>Optional</Typography>}
      <Typography className={styles.labelText}>{test.title}</Typography>
    </>
  );

  const testDescription =
    test.description && test.description.length > 0 ? (
      <ReactMarkdown>{test.description}</ReactMarkdown>
    ) : (
      'No description'
    );

  const getResultIcon = () => {
    // TODO: Fix bug where old result session IDs are automatically set to the current session
    // TODO: Overwrites wait tests
    // Default to true to prevent icon display errors
    const resultIsInRun = test.result ? testRun?.results?.includes(test.result) : true;
    const isSameSession = testRun?.test_session_id === test.result?.test_session_id;
    if (testRunInProgress && isSameSession && !resultIsInRun) {
      return <PendingIcon color="disabled" />;
    }
    return <ResultIcon result={test.result} />;
  };

  return (
    <>
      <Box className={styles.listItem}>
        <ListItem>
          <div className={styles.testIcon}>{getResultIcon()}</div>
          <ListItemText primary={testLabel} />
          {messagesBadge}
          {requestsBadge}
          <TestRunButton
            runTests={runTests}
            runnable={test}
            testRunInProgress={testRunInProgress}
          />
          {expandButton}
        </ListItem>
        {test.result?.result_message && (
          <ReactMarkdown className={styles.resultMessageMarkdown}>
            {test.result.result_message}
          </ReactMarkdown>
        )}
      </Box>
      <Collapse in={open} className={styles.collapsible} unmountOnExit>
        <Divider />
        <Tabs
          value={panelIndex}
          className={styles.tabs}
          onChange={(_event, newIndex) => {
            setPanelIndex(newIndex);
          }}
          variant="fullWidth"
        >
          <Tab label="About" />
          <Tab label="Messages" />
          <Tab label="HTTP Requests" />
        </Tabs>
        <Divider />
        <TabPanel currentPanelIndex={panelIndex} index={0}>
          <Container className={styles.descriptionPanel}>
            <Typography variant="subtitle2">{testDescription}</Typography>
          </Container>
        </TabPanel>
        <TabPanel currentPanelIndex={panelIndex} index={1}>
          <MessagesList messages={test.result?.messages || []} />
        </TabPanel>
        <TabPanel currentPanelIndex={panelIndex} index={2}>
          <RequestsList
            requests={test.result?.requests || []}
            resultId={test.result?.id || ''}
            updateRequest={updateRequest}
          />
        </TabPanel>
      </Collapse>
    </>
  );
};

export default TestListItem;
