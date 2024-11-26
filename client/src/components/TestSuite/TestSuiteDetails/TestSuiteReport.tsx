import React, { FC } from 'react';
import TestGroupCard from '~/components/TestSuite/TestSuiteDetails/TestGroupCard';
import { TestGroup, Test, TestSuite, SuiteOptionChoice, Request } from '~/models/testSuiteModels';
import TestGroupListItem from './TestGroupListItem/TestGroupListItem';
import TestListItem from './TestListItem/TestListItem';
import {
  Avatar,
  Box,
  Button,
  Card,
  Divider,
  FormControlLabel,
  FormGroup,
  IconButton,
  Switch,
  Typography,
} from '@mui/material';
import PrintIcon from '@mui/icons-material/Print';
import useStyles from './styles';
import TestSuiteMessages from './TestSuiteMessages';
import { useAppStore } from '~/store/app';
import lightTheme from '~/styles/theme';

interface TestSuiteReportProps {
  testSuite: TestSuite;
  suiteOptions?: SuiteOptionChoice[];
  updateRequest?: (requestId: string, resultId: string, request: Request) => void;
}

const TestSuiteReport: FC<TestSuiteReportProps> = ({ testSuite, suiteOptions, updateRequest }) => {
  const { classes } = useStyles();
  const windowIsSmall = useAppStore((state) => state.windowIsSmall);
  const [showDetails, setShowDetails] = React.useState(false);
  const location = window?.location?.href?.split('#')?.[0];
  const suiteOptionsString =
    suiteOptions && suiteOptions.length > 0
      ? ` - ${suiteOptions.map((option) => option.label).join(', ')}`
      : '';

  // Pull report date from results or indicate there is no date
  const getReportDate = (): string => {
    // Set to most recent date from list of test group results
    const reportDate = testSuite.test_groups?.reduce((acc: Date, group: TestGroup) => {
      if (group.result?.updated_at) {
        const dateUpdated = new Date(group.result?.updated_at);
        if (dateUpdated > acc) {
          acc = dateUpdated;
        }
      }
      return acc;
    }, new Date(0));

    if (!testSuite.test_groups || reportDate?.getTime() === new Date(0).getTime()) {
      return 'N/A';
    }

    return Intl.DateTimeFormat('en', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: 'numeric',
      minute: 'numeric',
    }).format(reportDate);
  };

  const header = (
    <Card variant="outlined" sx={{ mb: 3 }}>
      <Box className={classes.testGroupCardHeader}>
        <span className={classes.testGroupCardHeaderText}>
          <Typography key="1" color="text.primary" className={classes.currentItem}>
            {testSuite.title} Report {suiteOptionsString}
          </Typography>
        </span>
        <span className={classes.testGroupCardHeaderButton}>
          <FormGroup>
            <FormControlLabel
              control={
                <Switch
                  checked={showDetails}
                  onChange={() => setShowDetails(!showDetails)}
                  inputProps={{ 'aria-label': 'controlled' }}
                  color="secondary"
                />
              }
              label="Show details"
            />
          </FormGroup>
        </span>
        <span className={classes.testGroupCardHeaderButton}>
          {windowIsSmall ? (
            <IconButton color="secondary" aria-label="Print Report" onClick={() => window.print()}>
              <Avatar sx={{ width: 32, height: 32, bgcolor: lightTheme.palette.secondary.main }}>
                <PrintIcon fontSize="small" />
              </Avatar>
            </IconButton>
          ) : (
            <Button
              variant="contained"
              color="secondary"
              size="small"
              disableElevation
              startIcon={<PrintIcon />}
              onClick={() => window.print()}
            >
              Print
            </Button>
          )}
        </span>
      </Box>
      <Divider />
      <Box p={1}>
        <Box className={classes.reportSummaryItems}>
          <Box px={2}>
            <Typography variant="h5" component="h1" textTransform="uppercase" fontWeight="bold">
              {testSuite.result?.result || 'pending'}
            </Typography>
            <Typography variant="button">Final Result</Typography>
          </Box>
          {testSuite.version && (
            <Box px={2}>
              <Typography variant="h5" component="h1" fontWeight="bold">
                {testSuite.version}
              </Typography>
              <Typography variant="button">Version</Typography>
            </Box>
          )}
          <Box px={2}>
            <Typography variant="h5" component="h1" fontWeight="bold">
              {getReportDate()}
            </Typography>
            <Typography variant="button">Report Date</Typography>
          </Box>
        </Box>
        {location && <Typography className={classes.reportSummaryURL}>{location}</Typography>}
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
