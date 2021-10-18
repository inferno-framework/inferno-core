import React, { FC } from 'react';
import useStyles from './styles';
import { Link, ListItem, ListItemIcon, ListItemText } from '@material-ui/core';
import { RunnableType, TestGroup } from 'models/testSuiteModels';
import FolderIcon from '@material-ui/icons/Folder';
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
  return (
    <ListItem className={styles.listItem}>
      <ListItemIcon>
        <FolderIcon />
      </ListItemIcon>
      <ListItemText
        primary={
          <Link color="inherit" href={`#${testGroup.id}`}>
            {testGroup.title}
          </Link>
        }
        secondary={testGroup.result?.result_message}
      />
      <div className={styles.testIcon}>{<ResultIcon result={testGroup.result} />}</div>
      <TestRunButton
        runnable={testGroup}
        runTests={runTests}
        testRunInProgress={testRunInProgress}
      />
    </ListItem>
  );
};

export default TestGroupListItem;
