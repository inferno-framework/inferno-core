import React, { FC } from 'react';
import { useLocation } from 'react-router-dom';
import useStyles from './styles';
import { Link, ListItem, ListItemIcon, ListItemText } from '@mui/material';
import { RunnableType, TestGroup } from 'models/testSuiteModels';
import FolderIcon from '@mui/icons-material/Folder';
import ResultIcon from './ResultIcon';
import TestRunButton from '../TestRunButton/TestRunButton';

interface TestGroupListItemProps {
  testGroup: TestGroup;
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  testRunInProgress: boolean;
}

const TestGroupListItem: FC<TestGroupListItemProps> = ({
  testGroup,
  runTests,
  testRunInProgress,
}) => {
  const styles = useStyles();
  const location = useLocation();

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
      <div className={styles.testIcon}>{<ResultIcon result={testGroup.result} />}</div>
      <TestRunButton
        runnable={testGroup}
        runnableType={RunnableType.TestGroup}
        runTests={runTests}
        testRunInProgress={testRunInProgress}
      />
    </ListItem>
  );
};

export default TestGroupListItem;
