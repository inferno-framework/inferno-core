import React, { FC } from 'react';
import useStyles from './styles';
import { Table, TableBody, TableRow, TableCell } from '@material-ui/core';
import { Message } from 'models/testSuiteModels';
import MardownDisplay from 'components/MarkdownDisplay/MarkdownDisplay';

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
              <MardownDisplay markdown={message.message} />
            </TableCell>
          </TableRow>
        );
      })
    ) : (
      <TableRow key={`msgRow-none`}>
        <TableCell>None</TableCell>
      </TableRow>
    );

  return (
    <Table>
      <TableBody>{messageListItems}</TableBody>
    </Table>
  );
};

export default MessagesList;
