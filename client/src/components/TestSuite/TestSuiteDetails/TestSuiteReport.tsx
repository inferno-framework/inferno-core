import React, { FC } from 'react';
import TestGroupCard from '~/components/TestSuite/TestSuiteDetails/TestGroupCard';
import {
  TestGroup,
  Test,
  TestSuite,
  SuiteOptionChoice,
  Request,
  Message,
} from '~/models/testSuiteModels';
import TestGroupListItem from './TestGroupListItem';
import TestListItem from './TestListItem/TestListItem';
import { Box, Button, Card, FormControlLabel, FormGroup, Switch, Typography } from '@mui/material';
import PrintIcon from '@mui/icons-material/Print';
import useStyles from './styles';
import TestSuiteMessages from './TestSuiteMessages';
import RequestsList from './TestListItem/RequestsList';
import MessagesList from './TestListItem/MessagesList';

interface TestSuiteReportProps {
  testSuite: TestSuite;
  suiteOptions?: SuiteOptionChoice[];
  updateRequest?: (requestId: string, resultId: string, request: Request) => void;
}

const TestSuiteReport: FC<TestSuiteReportProps> = ({ testSuite, suiteOptions, updateRequest }) => {
  const styles = useStyles();
  const [showDetails, setShowDetails] = React.useState(false);
  const location = window?.location?.href?.split('#')?.[0];
  const suiteOptionsString =
    suiteOptions && suiteOptions.length > 0
      ? ` - ${suiteOptions.map((option) => option.label).join(', ')}`
      : '';

  const header = (
    <Card variant="outlined" sx={{ mb: 3 }}>
      <Box className={styles.testGroupCardHeader}>
        <span className={styles.testGroupCardHeaderText}>
          <Typography key="1" color="text.primary" className={styles.currentItem}>
            {testSuite.title} Report {suiteOptionsString}
          </Typography>
        </span>
        <span className={styles.testGroupCardHeaderButton}>
          <FormGroup>
            <FormControlLabel
              control={
                <Switch
                  checked={showDetails}
                  onChange={() => {
                    setShowDetails(!showDetails);
                  }}
                  inputProps={{ 'aria-label': 'controlled' }}
                  color="secondary"
                />
              }
              label="Show details"
            />
          </FormGroup>
        </span>
        <span className={styles.testGroupCardHeaderButton}>
          <Button
            variant="contained"
            color="secondary"
            size="small"
            disableElevation
            startIcon={<PrintIcon />}
            onClick={() => {
              window.print();
            }}
          >
            Print
          </Button>
        </span>
      </Box>
      <Box p={1}>
        <Box className={styles.reportSummaryItems}>
          <Box px={2}>
            <Typography
              variant="h5"
              component="h1"
              textTransform="uppercase"
              sx={{ fontWeight: 'bold' }}
            >
              {testSuite.result?.result || 'pending'}
            </Typography>
            <Typography variant="button">Final Result</Typography>
          </Box>
          {testSuite.version && (
            <Box px={2}>
              <Typography variant="h5" component="h1" sx={{ fontWeight: 'bold' }}>
                {testSuite.version}
              </Typography>
              <Typography variant="button">Version</Typography>
            </Box>
          )}
          <Box px={2}>
            <Typography variant="h5" component="h1" sx={{ fontWeight: 'bold' }}>
              {Intl.DateTimeFormat('en', {
                year: 'numeric',
                month: 'short',
                day: 'numeric',
                hour: 'numeric',
                minute: 'numeric',
              }).format(new Date())}
            </Typography>
            <Typography variant="button">Report Date</Typography>
          </Box>
        </Box>
        {location && <Typography className={styles.reportSummaryURL}>{location}</Typography>}
      </Box>
    </Card>
  );

  const renderTestGroupDetails = (testGroup: TestGroup) => {
    // List of elements for each detail component
    const details: JSX.Element[] = [];

    if (testGroup.tests && updateRequest && showDetails) {
      // Pull out and flatten requests
      const requests: Request[] = testGroup.tests
        .reduce((requests: Request[], test) => {
          if (test.result && test.result.requests) {
            requests.push(...test.result.requests);
          }
          return requests;
        }, [])
        .flat();

      if (requests && requests.length > 0)
        details.push(
          <RequestsList
            requests={requests || []}
            resultId={testGroup.result?.id || ''}
            updateRequest={updateRequest}
          />
        );
    }

    if (testGroup.tests && showDetails) {
      // Pull out and flatten requests
      const messages: Message[] = testGroup.tests
        .reduce((messages: Message[], test) => {
          if (test.result && test.result.messages) {
            messages.push(...test.result.messages);
          }
          return messages;
        }, [])
        .flat();

      if (messages && messages.length > 0) {
        details.push(<MessagesList messages={messages} />);
      }
    }

    return details;
  };

  const renderTestChildren = () => {
    let listItems: JSX.Element[] = [];

    return testSuite.test_groups?.map((runnable) => {
      if (runnable.test_groups.length > 0) {
        listItems = runnable.test_groups.map((testGroup: TestGroup) => {
          return (
            <Box key={`li-${testGroup.id}`}>
              <TestGroupListItem testGroup={testGroup} testRunInProgress={false} view="report" />
              {updateRequest && renderTestGroupDetails(testGroup)}
            </Box>
          );
        });
      } else if ('tests' in runnable) {
        listItems = runnable.tests.map((test: Test) => {
          return (
            <Box key={`li-${test.id}`}>
              <TestListItem test={test} testRunInProgress={false} view="report" />
              {updateRequest && (
                <RequestsList
                  requests={test.result?.requests || []}
                  resultId={test.result?.id || ''}
                  updateRequest={updateRequest}
                />
              )}
            </Box>
          );
        });
      }

      return (
        <TestGroupCard
          key={`g-${runnable.id}`}
          runnable={runnable}
          testRunInProgress={false}
          view="report"
        >
          {listItems}
        </TestGroupCard>
      );
    });
  };

  return (
    <>
      <TestSuiteMessages
        messages={
          testSuite.configuration_messages?.filter((message) => message.type === 'error') || []
        }
        testSuiteId={testSuite.id}
      />
      {header}
      {renderTestChildren()}
    </>
  );
};

export default TestSuiteReport;
