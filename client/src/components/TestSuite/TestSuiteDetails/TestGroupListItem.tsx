import React, { FC } from 'react';
import useStyles from './styles';
import {
  Accordion,
  AccordionDetails,
  AccordionSummary,
  Box,
  Divider,
  Link,
  List,
  ListItem,
  ListItemText,
  Typography,
} from '@mui/material';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import FolderIcon from '@mui/icons-material/Folder';
import { Request, RunnableType, Test, TestGroup, TestRun } from 'models/testSuiteModels';
import ResultIcon from './ResultIcon';
import PendingIcon from '@mui/icons-material/Pending';
import TestRunButton from '../TestRunButton/TestRunButton';
import TestListItem from './TestListItem/TestListItem';
import { getPath } from 'api/infernoApiService';
import ReactMarkdown from 'react-markdown';

interface TestGroupListItemProps {
  testGroup: TestGroup;
  runTests?: (runnableType: RunnableType, runnableId: string) => void;
  updateRequest?: (requestId: string, resultId: string, request: Request) => void;
  testRun: TestRun | null;
  testRunInProgress: boolean;
  view: 'report' | 'run';
}

const TestGroupListItem: FC<TestGroupListItemProps> = ({
  testGroup,
  runTests,
  updateRequest,
  testRunInProgress,
  testRun,
  view,
}) => {
  const styles = useStyles();

  const renderGroupListItems = (): JSX.Element[] => {
    return testGroup.test_groups.map((tg: TestGroup) => (
      <TestGroupListItem
        key={`li-${tg.id}`}
        testGroup={tg}
        runTests={runTests}
        updateRequest={updateRequest}
        testRunInProgress={testRunInProgress}
        testRun={testRun}
        view={view}
      />
    ));
  };

  const renderTestListItems = (): JSX.Element[] => {
    return testGroup.tests.map((test: Test) => (
      <TestListItem
        key={`li-${test.id}`}
        test={test}
        runTests={runTests}
        updateRequest={updateRequest}
        testRunInProgress={testRunInProgress}
        view={view}
      />
    ));
  };

  const nestedDescriptionPanel = (
    <Box className={styles.nestedDescriptionContainer}>
      <Accordion
        disableGutters
        key={`${testGroup.id}-description`}
        className={styles.accordion}
        TransitionProps={{ unmountOnExit: true }}
      >
        <AccordionSummary
          aria-controls={`${testGroup.title}-description-header`}
          id={`${testGroup.title}-description-header`}
          expandIcon={<ExpandMoreIcon sx={{ padding: '0 5px' }} />}
        >
          <ListItem className={styles.testGroupCardList}>
            <ListItemText
              primary={
                <Typography className={styles.nestedDescriptionHeader}>
                  About {testGroup.short_title || testGroup.title}
                </Typography>
              }
            />
          </ListItem>
        </AccordionSummary>
        <Divider />
        <AccordionDetails className={styles.accordionDetailContainer}>
          <ReactMarkdown className={`${styles.accordionDetail} ${styles.nestedDescription}`}>
            {testGroup.description as string}
          </ReactMarkdown>
        </AccordionDetails>
      </Accordion>
    </Box>
  );

  const expandedGroupListItem = (
    <Accordion
      disableGutters
      className={styles.accordion}
      defaultExpanded={testGroup.result?.result == 'fail' || view == 'report' ? true : undefined}
      TransitionProps={{ unmountOnExit: true }}
    >
      <AccordionSummary
        aria-controls={`${testGroup.title}-header`}
        id={`${testGroup.title}-header`}
        // Toggle accordion expansion only on icon click
        sx={{
          pointerEvents: 'none',
        }}
        expandIcon={
          view === 'run' && (
            <ExpandMoreIcon
              sx={{
                pointerEvents: 'auto',
              }}
            />
          )
        }
      >
        <ListItem className={styles.testGroupCardList}>
          {testGroup.result && (
            <Box className={styles.testIcon}>{<ResultIcon result={testGroup.result} />}</Box>
          )}
          <ListItemText primary={testGroup.title} secondary={testGroup.result?.result_message} />
          {view === 'run' && runTests && (
            <TestRunButton
              runnable={testGroup}
              runnableType={RunnableType.TestGroup}
              runTests={runTests}
              testRunInProgress={testRunInProgress}
            />
          )}
        </ListItem>
      </AccordionSummary>
      <Divider />
      <AccordionDetails className={styles.accordionDetailContainer}>
        {testGroup.description && view == 'run' && nestedDescriptionPanel}
        <List className={styles.accordionDetail}>
          {'test_groups' in testGroup && renderGroupListItems()}
          {'tests' in testGroup && renderTestListItems()}
        </List>
      </AccordionDetails>
    </Accordion>
  );

  const getResultIcon = () => {
    const testRunResultIds = testRun?.results?.map((r) => r.test_id) || [];
    const groupIsFinished = testRunResultIds.includes(testGroup.id);
    if (testRunInProgress && !groupIsFinished) {
      return <PendingIcon color="disabled" />;
    }
    return <ResultIcon result={testGroup.result} />;
  };

  const folderGroupListItem = (
    <>
      <ListItem>
        {testGroup.result && <Box className={styles.testIcon}>{getResultIcon()}</Box>}
        <ListItemText
          primary={
            <Box sx={{ display: 'flex' }}>
              <FolderIcon className={styles.folderIcon} />
              <Link
                color="inherit"
                href={getPath(`${location.pathname}#${testGroup.id}`)}
                underline="hover"
              >
                {testGroup.title}
              </Link>
            </Box>
          }
          secondary={testGroup.result?.result_message}
        />
      </ListItem>
      <Divider />
    </>
  );

  return (
    <>{testGroup.expanded || view === 'report' ? expandedGroupListItem : folderGroupListItem}</>
  );
};

export default TestGroupListItem;
