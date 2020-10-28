import React, { FC, Fragment } from 'react';
import useStyles from './styles';
import {
  Collapse,
  Divider,
  IconButton,
  ListItem,
  ListItemSecondaryAction,
  ListItemText,
  Tab,
  Tabs,
  Tooltip,
} from '@material-ui/core';
import { RunnableType, Test, Request } from 'models/testSuiteModels';
import PlayArrowIcon from '@material-ui/icons/PlayArrow';
import { getIconFromResult } from '../TestSuiteUtilities';
import TabPanel from './TabPanel';
import MessagesList from './MessagesList';
import RequestsList from './RequestsList';
import Badge from '@material-ui/core/Badge';
import NoteIcon from '@material-ui/icons/Note';
import HttpIcon from '@material-ui/icons/Http';

interface TestListItemProps extends Test {
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  updateRequest: (requestId: string, resultId: string, request: Request) => void;
  alternateRow: boolean;
}

const TestListItem: FC<TestListItemProps> = ({
  title,
  result,
  id,
  alternateRow,
  runTests,
  updateRequest,
}) => {
  const styles = useStyles();

  const [open, setOpen] = React.useState(false);
  const [panelIndex, setPanelIndex] = React.useState(0);

  const messagesBadge =
    result?.messages && result.messages.length > 0 ? (
      <Tooltip className={styles.testBadge} title={`${result.messages.length} messages`}>
        <Badge color="secondary" badgeContent={result.messages.length}>
          <NoteIcon />
        </Badge>
      </Tooltip>
    ) : null;

  const requestsBadge =
    result?.requests && result.requests.length > 0 ? (
      <Tooltip className={styles.testBadge} title={`${result.requests.length} http requests`}>
        <Badge color="secondary" badgeContent={result.requests.length}>
          <HttpIcon />
        </Badge>
      </Tooltip>
    ) : null;

  return (
    <Fragment>
      <ListItem
        button
        onClick={() => setOpen(!open)}
        className={alternateRow ? styles.testListItemAlternateRow : ''}
      >
        <ListItemText primary={title} secondary={result?.result_message} />
        {requestsBadge}
        {messagesBadge}
        <div className={styles.testIcon}>{getIconFromResult(result)}</div>
        <ListItemSecondaryAction>
          <IconButton
            edge="end"
            onClick={() => {
              runTests(RunnableType.Test, id);
            }}
            data-testid={`${id}-run-button`}
          >
            <PlayArrowIcon />
          </IconButton>
        </ListItemSecondaryAction>
      </ListItem>
      <Collapse in={open} timeout="auto" unmountOnExit>
        <Divider />
        <Tabs
          value={panelIndex}
          className={styles.tabs}
          onChange={(_event, newIndex) => {
            setPanelIndex(newIndex);
          }}
          variant="fullWidth"
        >
          <Tab label="Messages" />
          <Tab label="HTTP Requests" />
        </Tabs>
        <TabPanel currentPanelIndex={panelIndex} index={0}>
          <MessagesList messages={result?.messages || []} />
        </TabPanel>
        <TabPanel currentPanelIndex={panelIndex} index={1}>
          <RequestsList
            requests={result?.requests || []}
            resultId={result?.id || ''}
            updateRequest={updateRequest}
          />
        </TabPanel>
      </Collapse>
    </Fragment>
  );
};

export default TestListItem;
