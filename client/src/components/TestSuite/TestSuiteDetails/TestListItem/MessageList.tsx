import React, { FC } from 'react';
import useStyles from './styles';
import { Table, TableBody, TableRow, TableCell, Typography, TableHead, Box } from '@mui/material';
import { Message } from '~/models/testSuiteModels';
import Markdown from 'react-markdown';

import MessageType from './MessageType';
import { sortByMessageType } from './helper';
import remarkGfm from 'remark-gfm';

interface MessageListProps {
  messages: Message[];
}

const MessageList: FC<MessageListProps> = ({ messages }) => {
  const { classes } = useStyles();

  const headerTitles = ['Type', 'Message'];
  const messageListHeader = (
    <TableRow key="msg-header">
      {headerTitles.map((title) => (
        <TableCell key={title} className={title === 'Message' ? classes.messageMessage : ''}>
          <Typography variant="overline" className={classes.bolderText}>
            {title}
          </Typography>
        </TableCell>
      ))}
    </TableRow>
  );

  const messageListItems = sortByMessageType(messages).map((message: Message, index: number) => {
    return (
      <TableRow key={`msgRow-${index}`}>
        <TableCell>
          <MessageType type={message.type} />
        </TableCell>
        <TableCell className={classes.messageMessage}>
          <Markdown remarkPlugins={[remarkGfm]}>{message.message}</Markdown>
        </TableCell>
      </TableRow>
    );
  });

  return messages.length > 0 ? (
    <Table size="small">
      <TableHead>{messageListHeader}</TableHead>
      <TableBody>{messageListItems}</TableBody>
    </Table>
  ) : (
    <Box p={2}>
      <Typography variant="subtitle2" component="p">
        No Messages
      </Typography>
    </Box>
  );
};

export default MessageList;
