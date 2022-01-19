import React, { FC } from 'react';
import { useLocation } from 'react-router-dom';
import useStyles from './styles';
import { CircularProgress, Link, ListItem, ListItemIcon, ListItemText } from '@mui/material';
import { Result, RunnableType, TestGroup } from 'models/testSuiteModels';
import FolderIcon from '@mui/icons-material/Folder';
import ResultIcon from './ResultIcon';
import TestRunButton from '../TestRunButton/TestRunButton';

interface TestGroupListItemProps {
  testGroup: TestGroup;
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  currentTest: Result | null;
  testRunInProgress: boolean;
}

const TestGroupListItem: FC<TestGroupListItemProps> = ({
  testGroup,
  runTests,
  currentTest,
  testRunInProgress,
}) => {
  const styles = useStyles();
  const location = useLocation();

  const getResultIcon = () => {
    if (testRunInProgress && currentTest?.test_id?.includes(testGroup.id)) {
      return <CircularProgress size={18} />;
    } else if (
      testRunInProgress &&
      currentTest?.test_run_id !== testGroup?.result?.test_run_id &&
      testGroup?.result?.test_group_id?.includes(currentTest?.test_id as string)
    ) {
      // If test is running and result is not from current run but is in the
      // same group, show nothing
      return null;
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
        runnable={testGroup}
        runTests={runTests}
        testRunInProgress={testRunInProgress}
      />
    </ListItem>
  );
};

export default TestGroupListItem;
