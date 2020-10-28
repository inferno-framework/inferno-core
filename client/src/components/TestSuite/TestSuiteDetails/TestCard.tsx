import React, { FC } from 'react';
import useStyles from './styles';
import {
  ButtonBase,
  Card,
  Collapse,
  Divider,
  IconButton,
  Tab,
  Tabs,
  Tooltip,
  Typography,
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

interface TestCardProps extends Test {
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  updateRequest: (requestId: string, resultId: string, request: Request) => void;
}

const TestCard: FC<TestCardProps> = ({ title, result, id, runTests, updateRequest }) => {
  const styles = useStyles();

  const [open, setOpen] = React.useState(false);
  const [panelIndex, setPanelIndex] = React.useState(0);

  const resultMessage = result?.result_message ? (
    <Typography color="textSecondary" className={styles.cardTitleText} variant="caption">
      {result.result_message}
    </Typography>
  ) : null;

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
      <Tooltip className={styles.testBadge} title={`${result.requests.length} HTTP requests`}>
        <Badge color="secondary" badgeContent={result.requests.length}>
          <HttpIcon />
        </Badge>
      </Tooltip>
    ) : null;

  const cardHeader = (
    <ButtonBase
      className={styles.testCardButton}
      onClick={() => {
        setOpen(!open);
      }}
      component="div"
    >
      <div className={styles.testCardTitle}>
        <Typography className={styles.cardTitleText} variant="h6">
          {title}
        </Typography>
        {requestsBadge}
        {messagesBadge}
        <div className={styles.testIcon}>{getIconFromResult(result)}</div>
        <IconButton
          onClick={(event) => {
            event.stopPropagation();
            runTests(RunnableType.Test, id);
          }}
          data-testid={`${id}-run-button`}
        >
          <PlayArrowIcon />
        </IconButton>
      </div>
      {resultMessage}
    </ButtonBase>
  );

  return (
    <Card className={styles.card}>
      {cardHeader}
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
            updateRequest={updateRequest}
            resultId={result?.id || ''}
            requests={result?.requests || []}
          />
        </TabPanel>
      </Collapse>
    </Card>
  );
};

export default TestCard;
