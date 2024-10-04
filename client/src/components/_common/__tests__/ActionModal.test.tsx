import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import ThemeProvider from 'components/ThemeProvider';
import { SnackbarProvider } from 'notistack';

import { expect, test, vi } from 'vitest';
import ActionModal from '../ActionModal';

const cancelTestRunMock = vi.fn();

test('Modal visible and inputs are shown', () => {
  render(
    <ThemeProvider>
      <SnackbarProvider>
        <ActionModal
          modalVisible={true}
          message="Mock action message"
          cancelTestRun={cancelTestRunMock}
        />
      </SnackbarProvider>
    </ThemeProvider>,
  );

  const messageText = screen.getByText('Mock action message');
  expect(messageText).toBeVisible();
});

test('Pressing cancel hides the modal', async () => {
  render(
    <ThemeProvider>
      <SnackbarProvider>
        <ActionModal
          modalVisible={true}
          message="Mock action message"
          cancelTestRun={cancelTestRunMock}
        />
      </SnackbarProvider>
    </ThemeProvider>,
  );

  const cancelButton = screen.getByTestId('cancel-button');
  await userEvent.click(cancelButton);
  expect(cancelTestRunMock).toHaveBeenCalled();
});
