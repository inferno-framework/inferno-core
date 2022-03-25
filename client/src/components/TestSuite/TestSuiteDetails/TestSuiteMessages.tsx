import React, { FC } from 'react';
import { Alert, Box, Card, Collapse, Typography, styled } from '@mui/material';
import IconButton, { IconButtonProps } from '@mui/material/IconButton';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import { Message, ViewType } from 'models/testSuiteModels';

interface ExpandMoreProps extends IconButtonProps {
  expand: boolean;
}

const ExpandMore = styled((props: ExpandMoreProps) => {
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const { expand, ...other } = props;
  return <IconButton {...other} />;
})(({ theme, expand }) => ({
  transform: !expand ? 'rotate(0deg)' : 'rotate(180deg)',
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
  const [expanded, setExpanded] = React.useState<boolean>(false);

  const trimmedMessageLength = 80;
  const shortMessage =
    message.message.length <= trimmedMessageLength
      ? message.message
      : `${message.message.substring(0, trimmedMessageLength)}...`;

  const handleExpandClick = () => {
    setExpanded(!expanded);
  };

  return (
    <Box onClick={handleExpandClick}>
      <Alert
        severity={message.type}
        variant={view === 'config' ? 'standard' : 'filled'}
        sx={{ marginBottom: '8px' }}
      >
        {shortMessage}
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
      </Alert>
      <Collapse in={expanded} unmountOnExit sx={{ marginBottom: '8px' }}>
        <Card variant="outlined">
          <Typography>{message.message}</Typography>
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
