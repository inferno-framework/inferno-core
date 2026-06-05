import React, { act } from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import ThemeProvider from 'components/ThemeProvider';
import { SnackbarProvider } from 'notistack';

import { afterEach, beforeEach, describe, expect, test, vi } from 'vitest';
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

test('No countdown shown when waitTimeout prop is absent (component fallback)', () => {
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

  expect(screen.queryByText(/This test will expire in/)).toBeNull();
  expect(screen.queryByText(/This test has expired/)).toBeNull();
});

describe('Countdown timer', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  test('Shows countdown text when waitTimeout is provided', () => {
    const waitTimeout = new Date(Date.now() + 120_000).toISOString();

    render(
      <ThemeProvider>
        <SnackbarProvider>
          <ActionModal
            modalVisible={true}
            message="Mock action message"
            cancelTestRun={cancelTestRunMock}
            waitTimeout={waitTimeout}
          />
        </SnackbarProvider>
      </ThemeProvider>,
    );

    expect(screen.getByText(/This test will expire in/)).toBeVisible();
    expect(screen.getByText(/120 seconds/)).toBeVisible();
    expect(screen.getByText(/Perform the needed action before the time expires/)).toBeVisible();
  });

  test('Countdown seconds value is rendered in a bold element', () => {
    const waitTimeout = new Date(Date.now() + 120_000).toISOString();

    render(
      <ThemeProvider>
        <SnackbarProvider>
          <ActionModal
            modalVisible={true}
            message="Mock action message"
            cancelTestRun={cancelTestRunMock}
            waitTimeout={waitTimeout}
          />
        </SnackbarProvider>
      </ThemeProvider>,
    );

    const boldEl = screen.getByText(/120 seconds/);
    expect(boldEl.tagName).toBe('STRONG');
  });

  test('Countdown decrements after one second', async () => {
    const waitTimeout = new Date(Date.now() + 120_000).toISOString();

    render(
      <ThemeProvider>
        <SnackbarProvider>
          <ActionModal
            modalVisible={true}
            message="Mock action message"
            cancelTestRun={cancelTestRunMock}
            waitTimeout={waitTimeout}
          />
        </SnackbarProvider>
      </ThemeProvider>,
    );

    expect(screen.getByText(/120 seconds/)).toBeVisible();

    await act(async () => {
      vi.advanceTimersByTime(1000);
    });

    expect(screen.getByText(/119 seconds/)).toBeVisible();
  });

  test('Shows expired message when countdown reaches zero', async () => {
    const waitTimeout = new Date(Date.now() + 1000).toISOString();

    render(
      <ThemeProvider>
        <SnackbarProvider>
          <ActionModal
            modalVisible={true}
            message="Mock action message"
            cancelTestRun={cancelTestRunMock}
            waitTimeout={waitTimeout}
          />
        </SnackbarProvider>
      </ThemeProvider>,
    );

    await act(async () => {
      vi.advanceTimersByTime(2000);
    });

    const expiredText = screen.getByText(/This test has expired. Click CANCEL to restart the test./);
    expect(expiredText).toBeVisible();
    expect(screen.queryByText(/This test will expire in/)).toBeNull();
  });

  test('No countdown shown when modal is not visible', () => {
    const waitTimeout = new Date(Date.now() + 120_000).toISOString();

    render(
      <ThemeProvider>
        <SnackbarProvider>
          <ActionModal
            modalVisible={false}
            message="Mock action message"
            cancelTestRun={cancelTestRunMock}
            waitTimeout={waitTimeout}
          />
        </SnackbarProvider>
      </ThemeProvider>,
    );

    expect(screen.queryByText(/This test will expire in/)).toBeNull();
    expect(screen.queryByText(/This test has expired/)).toBeNull();
  });
});
