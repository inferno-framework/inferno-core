import React, { FC } from 'react';
import useStyles from './styles';
import { Table, TableBody, TableRow, TableCell, Typography } from '@mui/material';
import { Message } from 'models/testSuiteModels';
import ReactMarkdown from 'react-markdown';

interface MessagesListProps {
  messages: Message[];
}

const MessagesList: FC<MessagesListProps> = ({ messages }) => {
  const styles = useStyles();

  const messageListItems =
    messages.length > 0 ? (
      messages.map((message: Message, index: number) => {
        return (
          <TableRow key={`msgRow-${index}`}>
            <TableCell>
              <span className={styles.messageType}>{message.type}:</span>
            </TableCell>
            <TableCell className={styles.messageMessage}>
              <ReactMarkdown>{message.message}</ReactMarkdown>
            </TableCell>
          </TableRow>
        );
      })
    ) : (
      <TableRow key={`msgRow-none`}>
        <TableCell>
          <Typography>None</Typography>
        </TableCell>
      </TableRow>
    );

  return (
    <Table>
      <TableBody>{messageListItems}</TableBody>
    </Table>
  );
};

export default MessagesList;
