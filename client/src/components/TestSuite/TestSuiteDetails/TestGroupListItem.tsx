import React, { FC } from 'react';
import useStyles from './styles';
import { IconButton, ListItem, ListItemSecondaryAction, ListItemText } from '@material-ui/core';
import { RunnableType, TestGroup } from 'models/testSuiteModels';
import PlayArrowIcon from '@material-ui/icons/PlayArrow';
import { getIconFromResult } from '../TestSuiteUtilities';

interface TestGroupListItemProps extends TestGroup {
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  setSelectedRunnable: (id: string, type: RunnableType) => void;
  alternateRow: boolean;
}

const TestGroupListItem: FC<TestGroupListItemProps> = ({
  title,
  result,
  id,
  alternateRow,
  runTests,
  setSelectedRunnable,
}) => {
  const styles = useStyles();

  return (
    <ListItem className={alternateRow ? styles.testListItemAlternateRow : ''}>
      <ListItemText
        primary={
          <span
            onClick={(event) => {
              event.stopPropagation();
              setSelectedRunnable(id, RunnableType.TestGroup);
            }}
            className={styles.clickableText}
          >
            {title}
          </span>
        }
        secondary={result?.result_message}
      />
      <div className={styles.testIcon}>{getIconFromResult(result)}</div>
      <ListItemSecondaryAction>
        <IconButton
          edge="end"
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
