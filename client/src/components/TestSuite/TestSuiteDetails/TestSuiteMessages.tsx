import React, { FC } from 'react';
import { Message } from 'models/testSuiteModels';
import Alert from '@mui/material/Alert';

interface TestSuiteMessagesProps {
  messages: Message[];
}

const TestSuiteMessages: FC<TestSuiteMessagesProps> = ({ messages }) => {
  if (messages.length == 0) {
    return <div></div>;
  }

  const errorMessages = messages.filter((message) => message.type === 'error');
  const warningMessages = messages.filter((message) => message.type === 'warning');
  const infoMessages = messages.filter((message) => message.type === 'info');

  const sortedMessages = [...errorMessages, ...warningMessages, ...infoMessages];

  const alerts = sortedMessages.map((message) => {
    return (
      <Alert variant="filled" severity={message.type}>
        {message.message}
      </Alert>
    );
  });

  return <div>{alerts}</div>;
};

export default TestSuiteMessages;
