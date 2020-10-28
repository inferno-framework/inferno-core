import React, { FC } from 'react';
import { TestSuite, TestGroup, RunnableType, Request } from 'models/testSuiteModels';
import { IconButton, Typography } from '@material-ui/core';
import useStyles from './styles';
import PlayArrowIcon from '@material-ui/icons/PlayArrow';
import { getIconFromResult } from '../TestSuiteUtilities';
import TestGroupCard from './TestGroupCard';

export interface TestSuiteDetailsProps extends TestSuite {
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  setSelectedRunnable: (id: string, type: RunnableType) => void;
  updateRequest: (requestId: string, resultId: string, request: Request) => void;
}

const TestSuiteDetails: FC<TestSuiteDetailsProps> = ({
  title,
  id,
  test_groups,
  result,
  runTests,
  setSelectedRunnable,
  updateRequest,
}) => {
  const styles = useStyles();

  function runSuite() {
    if (test_groups) {
      runTests(RunnableType.TestSuite, id);
    }
  }

  if (test_groups) {
    const testGroupList = test_groups.map((testGroup: TestGroup, _index: number) => (
      <TestGroupCard
        key={`card-${testGroup.id}`}
        {...testGroup}
        runTests={runTests}
        setSelectedRunnable={setSelectedRunnable}
        updateRequest={updateRequest}
      />
    ));

    return (
      <div>
        <div className={styles.testSuiteTitle} data-testid="testSuite-title">
          <Typography variant="h4" component="h4" className={styles.panelTitleText}>
            {title}
          </Typography>
          {getIconFromResult(result)}
          <IconButton
            className={styles.testSuiteTitleRunButton}
            onClick={() => runSuite()}
            data-testid="testSuite-run-button"
          >
            <PlayArrowIcon />
          </IconButton>
        </div>
        {testGroupList}
      </div>
    );
  } else {
    return <div>{title}</div>;
  }
};

export default TestSuiteDetails;
