import React, { FC } from 'react';
import { TestGroup, RunnableType, Test, Request } from 'models/testSuiteModels';
import { IconButton, Typography } from '@material-ui/core';
import useStyles from './styles';
import PlayArrowIcon from '@material-ui/icons/PlayArrow';
import { getIconFromResult } from '../TestSuiteUtilities';
import TestGroupCard from './TestGroupCard';
import TestCard from './TestCard';

export interface TestGroupDetailsProps extends TestGroup {
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  setSelectedRunnable: (id: string, type: RunnableType) => void;
  updateRequest: (requestId: string, resultId: string, request: Request) => void;
}

const TestGroupDetails: FC<TestGroupDetailsProps> = ({
  title,
  id,
  test_groups,
  tests,
  result,
  runTests,
  setSelectedRunnable,
  updateRequest,
}) => {
  const styles = useStyles();

  function runSuite() {
    runTests(RunnableType.TestGroup, id);
  }

  let subRunnableList: JSX.Element[];
  if (test_groups.length > 0) {
    subRunnableList = test_groups.map((testGroup: TestGroup, _index: number) => (
      <TestGroupCard
        {...testGroup}
        runTests={runTests}
        setSelectedRunnable={setSelectedRunnable}
        updateRequest={updateRequest}
        key={`tgCard-${testGroup.id}`}
      />
    ));
  } else {
    subRunnableList = tests.map((test: Test, _index: number) => {
      return (
        <TestCard
          {...test}
          runTests={runTests}
          updateRequest={updateRequest}
          key={`testCard-${test.id}`}
        />
      );
    });
  }

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
      {subRunnableList}
    </div>
  );
};

export default TestGroupDetails;
