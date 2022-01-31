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
    // TODO: Fix bug where old result session IDs are automatically set to the current session
    const testRunResultIds = testRun?.results?.map((r) => r.test_id) || [];
    const groupIsFinished = testRunResultIds.includes(testGroup.id);
    const isSameSession = testGroup.tests[0]?.result
      ? testRun?.test_session_id === testGroup.tests[0].result?.test_session_id
      : false;
    if (testRunInProgress && isSameSession && !groupIsFinished) {
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
