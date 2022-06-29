import React, { FC } from 'react';
import useStyles from './styles';
import { Table, TableBody, TableRow, TableCell, Typography, TableHead, Box } from '@mui/material';
import { Message } from '~/models/testSuiteModels';
import ReactMarkdown from 'react-markdown';

import MessageType from './MessageType';
import { sortByMessageType } from './helper';

interface MessagesListProps {
  messages: Message[];
}

const MessagesList: FC<MessagesListProps> = ({ messages }) => {
  const styles = useStyles();

  const headerTitles = ['Type', 'Message'];
  const messageListHeader = (
    <TableRow key="msg-header">
      {headerTitles.map((title) => (
        <TableCell key={title} className={title === 'Message' ? styles.messageMessage : ''}>
          <Typography variant="overline" className={styles.bolderText}>
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
        <TableCell className={styles.messageMessage}>
          <ReactMarkdown>{message.message}</ReactMarkdown>
        </TableCell>
      </TableRow>
    );
  });

  return messages.length > 0 ? (
    <Table>
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

export default MessagesList;
