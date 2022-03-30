import React, { FC } from 'react';
import { useHistory } from 'react-router-dom';
import { Alert, Box, Card, Collapse, Typography, styled, CardContent } from '@mui/material';
import IconButton, { IconButtonProps } from '@mui/material/IconButton';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import { Message, ViewType } from 'models/testSuiteModels';
import useStyles from './styles';

interface ExpandMoreProps extends IconButtonProps {
  expand: boolean;
}

const ExpandMore = styled((props: ExpandMoreProps) => {
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const { expand, ...other } = props;
  return <IconButton disableRipple {...other} />;
})(({ theme, expand }) => ({
  transform: !expand ? 'rotate(0deg)' : 'rotate(180deg)',
  padding: 0,
  marginLeft: 'auto',
  transition: theme.transitions.create('transform', {
    duration: theme.transitions.duration.shortest,
  }),
}));

interface TestSuiteMessageProps {
  message: Message;
  view: ViewType;
}

const TestSuiteMessage: FC<TestSuiteMessageProps> = ({ message, view }) => {
  const styles = useStyles();
  const history = useHistory();
  const [expanded, setExpanded] = React.useState<boolean>(false);

  const handleExpandClick = () => {
    if (view === 'config') {
      setExpanded(!expanded);
    } else {
      history.push(`${history.location.pathname}${history.location.hash}/config`);
    }
  };

  return (
    <Box>
      <Box className={styles.alertCursor}>
        <Alert
          severity={message.type}
          variant={view === 'config' ? 'standard' : 'filled'}
          onClick={handleExpandClick}
          className={styles.alert}
        >
          <Box sx={{ display: 'flex' }}>
            <Box className={styles.alertMessage}>{message.message}</Box>
            {view === 'config' && (
              <ExpandMore
                expand={expanded}
                onClick={handleExpandClick}
                aria-expanded={expanded}
                aria-label="show more"
              >
                <ExpandMoreIcon />
              </ExpandMore>
            )}
          </Box>
        </Alert>
      </Box>
      <Collapse in={expanded} unmountOnExit sx={{ mb: '8px' }}>
        <Card variant="outlined">
          <CardContent>
            <Typography variant="body2">{message.message}</Typography>
          </CardContent>
        </Card>
      </Collapse>
    </Box>
  );
};

interface TestSuiteMessagesProps {
  messages: Message[];
  view: ViewType;
}

const TestSuiteMessages: FC<TestSuiteMessagesProps> = ({ messages, view }) => {
  const errorMessages = messages.filter((message) => message.type === 'error');
  const warningMessages = messages.filter((message) => message.type === 'warning');
  const infoMessages = messages.filter((message) => message.type === 'info');
  const sortedMessages = [...errorMessages, ...warningMessages, ...infoMessages];

  return (
    <>
      {sortedMessages.map((message, index) => (
        <TestSuiteMessage message={message} view={view} key={index} />
      ))}
    </>
  );
};

export default TestSuiteMessages;
