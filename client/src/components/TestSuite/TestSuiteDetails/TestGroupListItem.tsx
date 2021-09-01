import React, { FC } from 'react';
import useStyles from './styles';
import {
  IconButton,
  Link,
  ListItem,
  ListItemIcon,
  ListItemSecondaryAction,
  ListItemText,
} from '@material-ui/core';
import { RunnableType, TestGroup } from 'models/testSuiteModels';
import PlayArrowIcon from '@material-ui/icons/PlayArrow';
import FolderIcon from '@material-ui/icons/Folder';
import ResultIcon from './ResultIcon';

interface TestGroupListItemProps extends TestGroup {
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  testRunInProgress: boolean;
}

const TestGroupListItem: FC<TestGroupListItemProps> = ({
  title,
  result,
  id,
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
          <Link color="inherit" href={`#${id}`}>
            {title}
          </Link>
        }
        secondary={result?.result_message}
      />
      <div className={styles.testIcon}>{<ResultIcon result={result} />}</div>
      <ListItemSecondaryAction>
        <IconButton
          disabled={testRunInProgress}
          edge="end"
          size="small"
          onClick={() => {
            runTests(RunnableType.TestGroup, id);
          }}
          data-testid={`${id}-run-button`}
        >
          <PlayArrowIcon />
        </IconButton>
      </ListItemSecondaryAction>
    </ListItem>
  );
};

export default TestGroupListItem;
