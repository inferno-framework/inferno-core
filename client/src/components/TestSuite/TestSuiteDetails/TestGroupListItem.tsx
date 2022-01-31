import React, { FC } from 'react';
import { useLocation } from 'react-router-dom';
import useStyles from './styles';
import { Link, ListItem, ListItemIcon, ListItemText } from '@mui/material';
import PendingIcon from '@mui/icons-material/Pending';
import FolderIcon from '@mui/icons-material/Folder';
import { RunnableType, TestGroup, TestRun } from 'models/testSuiteModels';
import ResultIcon from './ResultIcon';
import TestRunButton from '../TestRunButton/TestRunButton';

interface TestGroupListItemProps {
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  testGroup: TestGroup;
  testRun: TestRun | null;
  testRunInProgress: boolean;
}

const TestGroupListItem: FC<TestGroupListItemProps> = ({
  runTests,
  testGroup,
  testRun,
  testRunInProgress,
}) => {
  const styles = useStyles();
  const location = useLocation();

  const getResultIcon = () => {
    const testRunResultIds = testRun?.results?.map((r) => r.test_id) || [];
    const testGroupResultIds = testGroup?.tests?.map((t) => t.id) || [];

    const groupIsFinished = testGroupResultIds.every((test) => testRunResultIds.includes(test));

    // console.log(testRun?.test_group_id, testGroup.id, groupIsFinished);

    // if (testRunInProgress && testGroup.id.includes(testRun?.test_group_id as string)) {
    if (testRunInProgress && !groupIsFinished) {
      return <PendingIcon color="disabled" />;
    }
    return <ResultIcon result={testGroup.result} />;
  };

  return (
    <ListItem className={styles.listItem}>
      <ListItemIcon>
        <FolderIcon />
      </ListItemIcon>
      <ListItemText
        primary={
          <Link color="inherit" href={`${location.pathname}#${testGroup.id}`} underline="hover">
            {testGroup.title}
          </Link>
        }
        secondary={testGroup.result?.result_message}
      />
      <div className={styles.testIcon}>{getResultIcon()}</div>
      <TestRunButton
        runTests={runTests}
        runnable={testGroup}
        testRunInProgress={testRunInProgress}
      />
    </ListItem>
  );
};

export default TestGroupListItem;
