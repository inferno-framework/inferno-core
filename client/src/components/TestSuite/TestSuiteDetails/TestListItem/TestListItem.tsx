import React, { FC, useEffect } from 'react';
import useStyles from './styles';
import {
  Box,
  CircularProgress,
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
import { RunnableType, Test, Request, Result } from 'models/testSuiteModels';
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
  test: Test;
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  updateRequest: (requestId: string, resultId: string, request: Request) => void;
  currentTest: Result | null;
  testGroupId: string;
  testRunInProgress: boolean;
}

const TestListItem: FC<TestListItemProps> = ({
  test,
  runTests,
  updateRequest,
  currentTest,
  testGroupId,
  testRunInProgress,
}) => {
  const styles = useStyles();

  const [open, setOpen] = React.useState(false);
  const [panelIndex, setPanelIndex] = React.useState(0);
  const [isRunning, setIsRunning] = React.useState(false);

  const messagesBadge = test.result?.messages && test.result.messages.length > 0 && (
    <IconButton
      className={styles.testBadge}
      onClick={() => {
        setPanelIndex(1);
        setOpen(true);
      }}
    >
      <Badge badgeContent={test.result.messages.length} color="primary">
        <Tooltip title={`${test.result.messages.length} messages`}>
          <MailIcon color="secondary" />
        </Tooltip>
      </Badge>
    </IconButton>
  );

  const requestsBadge = test.result?.requests && test.result.requests.length > 0 && (
    <IconButton
      className={styles.testBadge}
      onClick={() => {
        setPanelIndex(2);
        setOpen(true);
      }}
    >
      <Badge badgeContent={test.result.requests.length} color="primary">
        <Tooltip title={`${test.result.requests.length} messages`}>
          <PublicIcon color="secondary" />
        </Tooltip>
      </Badge>
    </IconButton>
  );

  const expandButton = open ? (
    <IconButton onClick={() => setOpen(false)} size="small">
      <ExpandLessIcon />
    </IconButton>
  ) : (
    <IconButton onClick={() => setOpen(true)} size="small">
      <ExpandMoreIcon />
    </IconButton>
  );

  const testDescription =
    test.description && test.description.length > 0 ? (
      <ReactMarkdown>{test.description}</ReactMarkdown>
    ) : (
      'No description'
    );

  useEffect(() => {
    if (!testRunInProgress) setIsRunning(false);
  }, [testRunInProgress]);

  const getResultIcon = () => {
    // if (testRunInProgress && currentTest?.test_id === test.id) {
    //   return <CircularProgress size={18} />;
    // } else if (
    if (
      // testRunInProgress &&
      // // TODO: "from current run" portion is failing; test_run_id inaccurate?
      // currentTest?.test_run_id !== test.result?.test_run_id &&
      // testGroupId.includes(currentTest?.test_id as string)
      isRunning &&
      !currentTest?.result
    ) {
      // If test is running and result is not from current run but is in the
      // same group, show nothing
      return <CircularProgress size={18} />;
    }
    return <ResultIcon result={test.result} />;
  };

  const handleSetIsRunning = (val: boolean) => {
    setIsRunning(val);
  };

  return (
    <>
      <Box className={styles.listItem}>
        <ListItem>
          <div className={styles.testIcon}>{getResultIcon()}</div>
          <ListItemText primary={test.title} />
          {messagesBadge}
          {requestsBadge}
          <TestRunButton
            runnable={test}
            runTests={runTests}
            setIsRunning={handleSetIsRunning}
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
