import React, { FC } from 'react';
import TestGroupCard from 'components/TestSuite/TestSuiteDetails/TestGroupCard';
import { TestGroup, Test, TestSuite } from 'models/testSuiteModels';
import TestGroupListItem from './TestGroupListItem';
import TestListItem from './TestListItem/TestListItem';
import { Button, Card, Typography } from '@mui/material';
import PrintIcon from '@mui/icons-material/Print';
import useStyles from './styles';

interface TestSuiteReportProps {
  testSuite: TestSuite;
}

const TestSuiteReport: FC<TestSuiteReportProps> = ({ testSuite }) => {
  const styles = useStyles();

  let listItems: JSX.Element[] = [];
  const testChildren = testSuite.test_groups?.map((runnable) => {
    if (runnable.test_groups.length > 0) {
      listItems = runnable.test_groups.map((testGroup: TestGroup) => {
        return (
          <TestGroupListItem
            key={`li-${testGroup.id}`}
            testGroup={testGroup}
            testRunInProgress={false}
            view={'report'}
          />
        );
      });
    } else if ('tests' in runnable) {
      listItems = runnable.tests.map((test: Test) => {
        return (
          <TestListItem
            key={`li-${test.id}`}
            test={test}
            testRunInProgress={false}
            view={'report'}
          />
        );
      });
    }

    return (
      <TestGroupCard runnable={runnable} testRunInProgress={false} view={'report'}>
        {listItems}
      </TestGroupCard>
    );
  });

  const header = (
    <Card className={styles.testGroupCard} variant="outlined">
      <div className={styles.testGroupCardHeader}>
        <span className={styles.testGroupCardHeaderText}>
          <Typography key="1" color="text.primary" className={styles.currentItem}>
            {testSuite.title} Report
          </Typography>
        </span>
        <span className={styles.testGroupCardHeaderButton}>
          <Button
            variant="contained"
            color="secondary"
            className={styles.printButton}
            size="small"
            disableElevation
            onClick={() => {
              window.print();
            }}
            startIcon={<PrintIcon />}
          >
            Print
          </Button>
        </span>
      </div>
      {/* TODO: PUT SUMMARY RESULT, STATS AND VERSION INFO HERE */}
    </Card>
  );

  return (
    <>
      {header}
      {testChildren}
    </>
  );
};

export default TestSuiteReport;
