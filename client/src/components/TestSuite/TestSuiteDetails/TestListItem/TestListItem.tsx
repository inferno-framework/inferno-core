import React, { FC, useEffect } from 'react';
import useStyles from './styles';
import {
  Box,
  Divider,
  ListItemText,
  Typography,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Card,
} from '@mui/material';
import { RunnableType, Test, Request, ViewType } from '~/models/testSuiteModels';
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
import type { MessageCounts } from './helper';
import { countMessageTypes } from './helper';
import TestRunDetail from './TestRunDetail';
import type { TabProps } from './TestRunDetail';

interface TestListItemProps {
  test: Test;
  runTests?: (runnableType: RunnableType, runnableId: string) => void;
  updateRequest?: (requestId: string, resultId: string, request: Request) => void;
  showReportDetails?: boolean;
  view: ViewType;
}

const TestListItem: FC<TestListItemProps> = ({
  test,
  runTests,
  updateRequest,
  showReportDetails = false,
  view,
}) => {
  const styles = useStyles();
  const messagesExist = !!test.result?.messages && test.result?.messages.length > 0;
  const requestsExist = !!test.result?.requests && test.result?.requests.length > 0;
  const [itemMouseHover, setItemMouseHover] = React.useState(false);
  const [open, setOpen] = React.useState<boolean>(false);
  const [tabIndex, setTabIndex] = React.useState<number>(0);
  const tabs: TabProps[] = [
    { label: 'Messages', value: test.result?.messages },
    { label: 'Requests', value: test.result?.requests },
    { label: 'Inputs', value: test.result?.inputs },
    { label: 'Outputs', value: test.result?.outputs },
    { label: 'About', value: test.description },
  ];

  useEffect(() => {
    setOpen(view === 'report' && showReportDetails && (messagesExist || requestsExist));
  }, [showReportDetails]);

  const resultIcon = (
    <Box display="inline-flex">
      <ResultIcon result={test.result} isRunning={test.is_running} />
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
          setPanelIndex={setTabIndex}
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
          setPanelIndex={setTabIndex}
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
          setPanelIndex={setTabIndex}
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
      setPanelIndex={setTabIndex}
    />
  );

  const testRunButton = view === 'run' && runTests && (
    <Box onClick={(e) => e.stopPropagation()}>
      <TestRunButton runnable={test} runnableType={RunnableType.Test} runTests={runTests} />
    </Box>
  );

  const reportDetails = (
    <>
      {messagesExist && (
        <Card sx={requestsExist ? { mb: 2 } : {}}>
          <MessagesList messages={test.result?.messages || []} />
        </Card>
      )}
      {updateRequest && requestsExist && (
        <Card>
          <RequestsList
            requests={test.result?.requests || []}
            resultId={test.result?.id || ''}
            updateRequest={updateRequest}
            view="report"
          />
        </Card>
      )}
    </>
  );

  // Find first tab with data.  If no tabs have data, return the About tab index.
  const findPopulatedTabIndex = (): number => {
    const firstTab = tabs.findIndex(
      (tab) => tab.label !== 'About' && tab.value && tab.value?.length > 0
    );

    if (firstTab === -1) {
      return tabs.findIndex((tab) => tab.label === 'About');
    }
    return firstTab;
  };

  const handleAccordionClick = () => {
    setTabIndex(findPopulatedTabIndex());
    setOpen(!open);
  };

  return (
    <>
      <Accordion
        disableGutters
        className={styles.accordion}
        sx={view === 'report' ? { pointerEvents: 'none' } : {}}
        expanded={open}
        TransitionProps={{ unmountOnExit: true }}
        onClick={handleAccordionClick}
        onMouseEnter={() => setItemMouseHover(true)}
        onMouseLeave={() => setItemMouseHover(false)}
      >
        <AccordionSummary
          id={itemMouseHover ? '' : `${test.id}-summary`}
          data-testid={`${test.id}-summary`}
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
          <Box display="flex" alignItems="center" width="100%">
            {resultIcon}
            {testText}
            {renderProblemBadge(messageTypeCounts)}
            {requestsBadge}
            {testRunButton}
          </Box>
        </AccordionSummary>
        <Divider />
        {/* Remove default tooltip on hover */}
        <AccordionDetails
          title={itemMouseHover ? '' : `${test.id}-detail`}
          data-testid={`${test.id}-detail`}
          className={styles.accordionDetailContainer}
          onClick={(e) => e.stopPropagation()}
        >
          {view === 'run' && (
            <TestRunDetail
              test={test}
              tabs={tabs}
              currentTabIndex={tabIndex}
              setTabIndex={setTabIndex}
              updateRequest={updateRequest}
            />
          )}
          {view === 'report' && showReportDetails && reportDetails}
        </AccordionDetails>
      </Accordion>
    </>
  );
};

export default TestListItem;
