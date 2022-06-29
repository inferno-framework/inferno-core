import React, { FC, useEffect, useMemo } from 'react';
import useStyles from './styles';
import {
  Box,
  Divider,
  ListItem,
  ListItemText,
  Tab,
  Tabs,
  Tooltip,
  Badge,
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
import Cancel from '@mui/icons-material/Cancel';
import Warning from '@mui/icons-material/Warning';
import Info from '@mui/icons-material/Info';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import ReactMarkdown from 'react-markdown';
import TestRunButton from '~/components/TestSuite/TestRunButton/TestRunButton';
import { shouldShowDescription } from '~/components/TestSuite/TestSuiteUtilities';
import type { MessageCounts } from './helper';
import { countMessageTypes } from './helper';

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
  const openCondition =
    (test.result?.result === 'fail' || test.result?.result === 'error') && view !== 'report';
  const [open, setOpen] = React.useState(openCondition);
  const [panelIndex, setPanelIndex] = React.useState(0);

  useEffect(() => {
    if (openCondition) setOpen(true);
  }, [test.result]);

  const resultIcon = (
    <Box className={styles.testIcon}>
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
    />
  );

  // Custom icon button to resolve nested interactive control error
  const requestsBadge = test.result?.requests && test.result.requests.length > 0 && (
    <Badge
      badgeContent={test.result.requests.length}
      overlap="circular"
      classes={{ badge: styles.testBadge }}
    >
      <Tooltip describeChild title={`${test.result.requests.length} request(s)`}>
        <PublicIcon
          aria-label={`View ${test.result.requests.length} request(s)`}
          aria-hidden={false}
          tabIndex={0}
          color="secondary"
          className={styles.badgeIcon}
          onClick={(e) => {
            e.stopPropagation();
            if (view !== 'report') {
              setPanelIndex(0);
              setOpen(true);
            }
          }}
          onKeyDown={(e) => {
            e.stopPropagation();
            if (e.key === 'Enter' && view !== 'report') {
              setPanelIndex(0);
              setOpen(true);
            }
          }}
        />
      </Tooltip>
    </Badge>
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

  const a11yProps = (index: number) => ({
    id: `${test.id}-tab-${index}`,
    'aria-controls': `${test.id}-tabpanel-${index}`,
  });

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
          Icon={Cancel}
          counts={messageTypeCounts.errors}
          color={styles.error}
          badgeStyle={styles.errorBadge}
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
          setOpen={setOpen}
          setPanelIndex={setPanelIndex}
        />
      );
  };

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
            className={styles.tabs}
            onChange={(e, newIndex) => {
              setPanelIndex(newIndex);
            }}
          >
            <Tab label="Messages" {...a11yProps(0)} />
            <Tab label="HTTP Requests" {...a11yProps(1)} />
            <Tab label="Inputs" {...a11yProps(2)} />
            <Tab label="Outputs" {...a11yProps(3)} />
            <Tab label="About" {...a11yProps(4)} />
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
