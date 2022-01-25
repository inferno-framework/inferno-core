import React, { FC, useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import useStyles from './styles';
import { CircularProgress, Link, ListItem, ListItemIcon, ListItemText } from '@mui/material';
import { Result, RunnableType, TestGroup } from 'models/testSuiteModels';
import FolderIcon from '@mui/icons-material/Folder';
import ResultIcon from './ResultIcon';
import TestRunButton from '../TestRunButton/TestRunButton';

interface TestGroupListItemProps {
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  testGroup: TestGroup;
  currentTest: Result | null;
  parentIsRunning: boolean;
  testRunInProgress: boolean;
}

const TestGroupListItem: FC<TestGroupListItemProps> = ({
  runTests,
  testGroup,
  currentTest,
  parentIsRunning,
  testRunInProgress,
}) => {
  const styles = useStyles();
  const location = useLocation();
  const [isRunning, setIsRunning] = React.useState(testRunInProgress);

  const getResultIcon = () => {
    // if (
    //   testRunInProgress &&
    //   currentTest?.test_run_id !== testGroup?.result?.test_run_id &&
    //   testGroup?.result?.test_group_id?.includes(currentTest?.test_id as string)
    // )
    //   console.log(currentTest, testGroup);
    // console.log(currentTest?.test_run_id !== testGroup?.result?.test_run_id);

    // if (testRunInProgress && currentTest?.test_id?.includes(testGroup.id)) {
    //   return <CircularProgress size={18} />;
    // } else if (

    console.log(isRunning);
    

    if (
      // testRunInProgress &&
      // currentTest?.test_run_id !== testGroup?.result?.test_run_id &&
      // currentTest?.test_id?.includes(testGroup?.result?.test_group_id as string)
      isRunning
    ) {
      // If test is running and result is not from current run but is in the
      // same group, show nothing
      // return null;
      return <CircularProgress size={18} />;
    }
    return <ResultIcon result={testGroup.result} />;
  };

  const handleSetIsRunning = (val: boolean) => {
    setIsRunning(val);
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
        setIsRunning={handleSetIsRunning}
        testRunInProgress={testRunInProgress}
      />
    </ListItem>
  );
};

export default TestGroupListItem;
