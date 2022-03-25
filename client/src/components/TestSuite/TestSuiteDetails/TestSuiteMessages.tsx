import React, { FC } from 'react';
import { Message } from 'models/testSuiteModels';
import { Alert } from '@mui/material';

interface TestSuiteMessagesProps {
  messages: Message[];
}

const TestSuiteMessages: FC<TestSuiteMessagesProps> = ({ messages }) => {
  if (messages.length == 0) {
    return <></>;
  }

  console.log(messages);

  const errorMessages = messages.filter((message) => message.type === 'error');
  const warningMessages = messages.filter((message) => message.type === 'warning');
  const infoMessages = messages.filter((message) => message.type === 'info');

  const sortedMessages = [...errorMessages, ...warningMessages, ...infoMessages];

  const alerts = sortedMessages.map((message, index) => {
    const trimmedMessageLength = 100;
    let shortMessage = message.message;
    if (message.message.length > trimmedMessageLength)
      shortMessage = `${message.message.substring(0, trimmedMessageLength)}...`;

    return (
      <Alert variant="filled" key={index} severity={message.type} sx={{ marginBottom: '8px' }}>
        {shortMessage}
      </Alert>
    );
  });

  return <div>{alerts}</div>;
};

export default TestSuiteMessages;
