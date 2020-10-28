import React, { FC } from 'react';
import List from '@material-ui/core/List';
import useStyles from './styles';
import { Card, Divider, IconButton, Typography } from '@material-ui/core';
import { TestGroup, RunnableType, Test, Request } from 'models/testSuiteModels';
import PlayArrowIcon from '@material-ui/icons/PlayArrow';
import { getIconFromResult } from '../TestSuiteUtilities';
import TestListItem from './TestListItem';
import TestGroupListItem from './TestGroupListItem';

interface TestGroupProps extends TestGroup {
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  setSelectedRunnable: (id: string, type: RunnableType) => void;
  updateRequest: (requestId: string, resultId: string, request: Request) => void;
}

const TestGroupCard: FC<TestGroupProps> = ({
  title,
  test_groups,
  tests,
  result,
  id,
  runTests,
  setSelectedRunnable,
  updateRequest,
}) => {
  const styles = useStyles();

  const cardHeader = (
    <div className={styles.groupCardTitle}>
      <Typography className={styles.cardTitleText} variant="h5">
        <span
          className={styles.clickableText}
          onClick={(event) => {
            event.stopPropagation();
            setSelectedRunnable(id, RunnableType.TestGroup);
          }}
        >
          {title}
        </span>
      </Typography>
      <div className={styles.testIcon}>{getIconFromResult(result)}</div>
      <IconButton
        onClick={(event) => {
          event.stopPropagation();
          runTests(RunnableType.TestGroup, id);
        }}
        data-testid={`${id}-run-button`}
      >
        <PlayArrowIcon />
      </IconButton>
    </div>
  );

  let listItems: JSX.Element[];
  if (test_groups.length > 0) {
    listItems = test_groups.map((testGroup: TestGroup, index: number) => {
      return (
        <TestGroupListItem
          key={`li-${testGroup.id}`}
          {...testGroup}
          runTests={runTests}
          setSelectedRunnable={setSelectedRunnable}
          alternateRow={index % 2 == 1}
        />
      );
    });
  } else {
    listItems = tests.map((test: Test, index: number) => {
      return (
        <TestListItem
          key={`li-${test.id}`}
          {...test}
          runTests={runTests}
          alternateRow={index % 2 == 1}
          updateRequest={updateRequest}
        />
      );
    });
  }

  return (
    <Card className={styles.card}>
      {cardHeader}
      <Divider />
      <List>{listItems}</List>
    </Card>
  );
};

export default TestGroupCard;
