import React from 'react';
import { render } from '@testing-library/react';
import { SnackbarProvider } from 'notistack';
import ThemeProvider from 'components/ThemeProvider';

import MessageList from '../MessageList';
import { Message } from '~/models/testSuiteModels';
import { describe, expect, test } from 'vitest';

describe('The MessagesList component', () => {
  test('it renders all messages', () => {
    const messages: Message[] = [
      { message: 'info', type: 'info' },
      { message: 'warning', type: 'warning' },
      { message: 'error', type: 'error' },
    ];

    render(
      <ThemeProvider>
        <SnackbarProvider>
          <MessageList messages={messages} />
        </SnackbarProvider>
      </ThemeProvider>
    );

    const renderedMessages = document.querySelectorAll('tbody > tr');
    expect(renderedMessages.length).toEqual(messages.length);
  });
});
