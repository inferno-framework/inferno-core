import React, { FC } from 'react';
import TestGroupCard from '~/components/TestSuite/TestSuiteDetails/TestGroupCard';
import { TestGroup, Test, TestSuite, SuiteOptionChoice, Request } from '~/models/testSuiteModels';
import TestGroupListItem from './TestGroupListItem/TestGroupListItem';
import TestListItem from './TestListItem/TestListItem';
import { Box, Button, Card, FormControlLabel, FormGroup, Switch, Typography } from '@mui/material';
import PrintIcon from '@mui/icons-material/Print';
import useStyles from './styles';
import TestSuiteMessages from './TestSuiteMessages';

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

  const renderTestGroupChildren = (testGroup: TestGroup) => {
    if (testGroup.test_groups.length > 0) {
      return testGroup.test_groups.map((testGroup: TestGroup) => {
        return (
          <TestGroupListItem
            key={`li-${testGroup.id}`}
            testGroup={testGroup}
            updateRequest={updateRequest}
            showReportDetails={showDetails}
            view="report"
          />
        );
      });
    } else if (testGroup.tests.length > 0) {
      return testGroup.tests.map((test: Test) => {
        return (
          <TestListItem
            key={`li-${test.id}`}
            test={test}
            showReportDetails={showDetails}
            view="report"
          />
        );
      });
    }
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
      {testSuite.test_groups?.map((testGroup) => (
        <TestGroupCard key={`g-${testGroup.id}`} runnable={testGroup} view="report">
          {renderTestGroupChildren(testGroup)}
        </TestGroupCard>
      ))}
    </>
  );
};

export default TestSuiteReport;
