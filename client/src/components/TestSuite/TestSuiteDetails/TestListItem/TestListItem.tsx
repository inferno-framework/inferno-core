import React, { FC, useMemo } from 'react';
import useStyles from './styles';
import {
  Box,
  Divider,
  ListItem,
  ListItemText,
  Tab,
  Tabs,
  Typography,
  Accordion,
  AccordionSummary,
  AccordionDetails,
} from '@mui/material';
import { RunnableType, Test, Request, ViewType } from '~/models/testSuiteModels';
import TabPanel from './TabPanel';
import InputOutputsList from './InputOutputsList';
import MessagesList from './MessagesList';
import RequestsList from './RequestsList';
import ResultIcon from '../ResultIcon';
import ProblemBadge from './ProblemBadge';
import PublicIcon from '@mui/icons-material/Public';
import Error from '@mui/icons-material/Error';
import Warning from '@mui/icons-material/Warning';
import Info from '@mui/icons-material/Info';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import ReactMarkdown from 'react-markdown';
import TestRunButton from '~/components/TestSuite/TestRunButton/TestRunButton';
import { shouldShowDescription } from '~/components/TestSuite/TestSuiteUtilities';
import type { MessageCounts } from './helper';
import { countMessageTypes } from './helper';
import lightTheme from 'styles/theme';

interface TestListItemProps {
  test: Test;
  runTests?: (runnableType: RunnableType, runnableId: string) => void;
  updateRequest?: (requestId: string, resultId: string, request: Request) => void;
  testRunInProgress: boolean;
  view: ViewType;
}

const TestListItem: FC<TestListItemProps> = ({
  test,
  runTests,
  updateRequest,
  testRunInProgress,
  view,
}) => {
  const styles = useStyles();
  const [open, setOpen] = React.useState(false);
  const [panelIndex, setPanelIndex] = React.useState(0);

  const resultIcon = (
    <Box display="inline-flex">
      <ResultIcon result={test.result} />
    </Box>
  );

  const testLabel = (
    <>
      {test.short_id && <Typography className={styles.shortId}>{`${test.short_id} `}</Typography>}
      {test.optional && <Typography className={styles.optionalLabel}>{'Optional '}</Typography>}
      <Typography className={styles.labelText}>{test.title}</Typography>
    </>
  );

  const testText = (
    <ListItemText
      primary={testLabel}
      secondary={
        test.result?.result_message && (
          <ReactMarkdown className={styles.resultMessageMarkdown}>
            {test.result.result_message}
          </ReactMarkdown>
        )
      }
      secondaryTypographyProps={{ component: 'div' }}
      className={styles.testText}
    />
  );

  const messageTypeCounts: MessageCounts = (() => {
    if (test.result === undefined || !test.result?.messages)
      return { errors: 0, warnings: 0, infos: 0 };

    return countMessageTypes(test.result.messages);
  })();

  const renderProblemBadge = (messageTypeCounts: MessageCounts) => {
    if (view !== 'run') return null;

    if (messageTypeCounts.errors > 0)
      return (
        <ProblemBadge
          Icon={Error}
          counts={messageTypeCounts.errors}
          color={styles.error}
          badgeStyle={styles.errorBadge}
          description={`${messageTypeCounts.errors} message(s)`}
          view={view}
          panelIndex={0}
          setOpen={setOpen}
          setPanelIndex={setPanelIndex}
        />
      );

    if (messageTypeCounts.warnings > 0)
      return (
        <ProblemBadge
          Icon={Warning}
          counts={messageTypeCounts.warnings}
          color={styles.warning}
          badgeStyle={styles.warningBadge}
          description={`${messageTypeCounts.warnings} message(s)`}
          view={view}
          panelIndex={0}
          setOpen={setOpen}
          setPanelIndex={setPanelIndex}
        />
      );

    if (messageTypeCounts.infos > 0)
      return (
        <ProblemBadge
          Icon={Info}
          counts={messageTypeCounts.infos}
          color={styles.info}
          badgeStyle={styles.infoBadge}
          description={`${messageTypeCounts.infos} message(s)`}
          view={view}
          panelIndex={0}
          setOpen={setOpen}
          setPanelIndex={setPanelIndex}
        />
      );
  };

  const requestsBadge = test.result?.requests && test.result.requests.length > 0 && (
    <ProblemBadge
      Icon={PublicIcon}
      counts={test.result.requests.length}
      color={styles.request}
      badgeStyle={styles.requestBadge}
      description={`${test.result.requests.length} request(s)`}
      view={view}
      panelIndex={1}
      setOpen={setOpen}
      setPanelIndex={setPanelIndex}
    />
  );

  const testRunButton = view === 'run' && runTests && (
    <Box onClick={(e) => e.stopPropagation()}>
      <TestRunButton
        runnable={test}
        runnableType={RunnableType.Test}
        runTests={runTests}
        testRunInProgress={testRunInProgress}
      />
    </Box>
  );

  const testDescription: JSX.Element = (
    <ListItem>
      <Typography variant="subtitle2" component="div">
        {useMemo(
          () => (
            <ReactMarkdown>{test.description || ''}</ReactMarkdown>
          ),
          [test.description]
        )}
      </Typography>
    </ListItem>
  );

  const darkTabText = {
    '&.Mui-selected': {
      color: lightTheme.palette.common.orangeDarker,
    },
  };

  const a11yProps = (index: number) => ({
    id: `${test.id}-tab-${index}`,
    'aria-controls': `${test.id}-tabpanel-${index}`,
  });

  return (
    <>
      <Accordion
        disableGutters
        className={styles.accordion}
        sx={view === 'report' ? { pointerEvents: 'none' } : {}}
        expanded={open}
        TransitionProps={{ unmountOnExit: true }}
        onClick={() => setOpen(!open)}
      >
        <AccordionSummary
          id={`${test.id}-summary`}
          title={`${test.id}-summary`}
          aria-controls={`${test.id}-detail`}
          role={view === 'report' ? 'region' : 'button'}
          expandIcon={view === 'run' && <ExpandMoreIcon />}
          className={styles.accordionSummary}
          onKeyDown={(e) => {
            if (view !== 'report' && e.key === 'Enter') {
              setOpen(!open);
            }
          }}
        >
          <Box display="flex" alignItems="center" width={'100%'}>
            {resultIcon}
            {testText}
            {renderProblemBadge(messageTypeCounts)}
            {requestsBadge}
            {testRunButton}
          </Box>
        </AccordionSummary>
        <Divider />
        <AccordionDetails
          title={`${test.id}-detail`}
          className={styles.accordionDetailContainer}
          onClick={(e) => e.stopPropagation()}
        >
          <Tabs
            value={panelIndex}
            variant="scrollable"
            className={styles.tabs}
            onChange={(e, newIndex) => {
              setPanelIndex(newIndex);
            }}
          >
            <Tab label="Messages" {...a11yProps(0)} sx={darkTabText} />
            <Tab label="HTTP Requests" {...a11yProps(1)} sx={darkTabText} />
            <Tab label="Inputs" {...a11yProps(2)} sx={darkTabText} />
            <Tab label="Outputs" {...a11yProps(3)} sx={darkTabText} />
            <Tab label="About" {...a11yProps(4)} sx={darkTabText} />
          </Tabs>
          <Divider />
          <TabPanel id={test.id} currentPanelIndex={panelIndex} index={0}>
            <MessagesList messages={test.result?.messages || []} />
          </TabPanel>
          <TabPanel id={test.id} currentPanelIndex={panelIndex} index={1}>
            {updateRequest && (
              <RequestsList
                requests={test.result?.requests || []}
                resultId={test.result?.id || ''}
                updateRequest={updateRequest}
              />
            )}
          </TabPanel>
          <TabPanel id={test.id} currentPanelIndex={panelIndex} index={2}>
            <InputOutputsList
              inputOutputs={test.result?.inputs || []}
              noValuesMessage="No Inputs"
              headerName="Input"
            />
          </TabPanel>
          <TabPanel id={test.id} currentPanelIndex={panelIndex} index={3}>
            <InputOutputsList
              inputOutputs={test.result?.outputs || []}
              noValuesMessage="No Outputs"
              headerName="Output"
            />
          </TabPanel>
          <TabPanel id={test.id} currentPanelIndex={panelIndex} index={4}>
            {shouldShowDescription(test, testDescription) ? (
              testDescription
            ) : (
              <Box p={2}>
                <Typography variant="subtitle2" component="p">
                  No Description
                </Typography>
              </Box>
            )}
          </TabPanel>
        </AccordionDetails>
      </Accordion>
    </>
  );
};

export default TestListItem;
