import React, { FC } from 'react';
import TestGroupCard from 'components/TestSuite/TestSuiteDetails/TestGroupCard';
import {
  TestInput,
  RunnableType,
  TestRun,
  Result,
  TestSession,
  TestGroup,
  Test,
  TestSuite,
} from 'models/testSuiteModels';
import TestGroupListItem from './TestGroupListItem';
import { Button, Card, Typography } from '@mui/material';
import PrintIcon from '@mui/icons-material/Print';
import useStyles from './styles';

interface TestSuiteReportProps {
  testSuite: TestSuite;
}

const TestSuiteReport: FC<TestSuiteReportProps> = ({
  testSuite,
}) => {
  const styles = useStyles();

  let testChildren = testSuite.test_groups?.map((item) => {
    let listItems = item.test_groups.map((testGroup: TestGroup) => {
      return (
        <TestGroupListItem
          key={`li-${testGroup.id}`}
          testGroup={testGroup}
          runTests={() => {}}
          updateRequest={() => {}}
          testRunInProgress={false}
          view={'report'}
        />
      );
    });

    return (<TestGroupCard
      runTests={() => {}}
      runnable={item}
      testRunInProgress={false}
      view={'report'}>
        {listItems}
    </TestGroupCard>);
  })

  let header = (
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
          >Print</Button>
      </span>
    </div>
    {/* TODO: PUT SUMMARY RESULT, STATS AND VERSION INFO HERE */}
  </Card>
  )

  return (
    <>
      {header}
      {testChildren}
    </>
  );
};

export default TestSuiteReport;
