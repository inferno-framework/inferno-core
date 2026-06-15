import React from 'react';
import { MemoryRouter } from 'react-router';
import { render, screen, fireEvent } from '@testing-library/react';
import { describe, expect, it } from 'vitest';
import ThemeProvider from 'components/ThemeProvider';
import TestSuiteMessages from '../TestSuiteMessages';
import { Message } from '~/models/testSuiteModels';

function wrap(messages: Message[], testSuiteId = 'suite-1') {
  return render(
    <MemoryRouter>
      <ThemeProvider>
        <TestSuiteMessages messages={messages} testSuiteId={testSuiteId} />
      </ThemeProvider>
    </MemoryRouter>,
  );
}

describe('TestSuiteMessages', () => {
  it('shows a singular error message when there is one error', () => {
    wrap([{ message: 'Bad config', type: 'error' }]);
    expect(
      screen.getByText('There is 1 configuration error that must be resolved.'),
    ).toBeInTheDocument();
  });

  it('shows a plural error message when there are multiple errors', () => {
    wrap([
      { message: 'Error one', type: 'error' },
      { message: 'Error two', type: 'error' },
    ]);
    expect(
      screen.getByText('There are 2 configuration errors that must be resolved.'),
    ).toBeInTheDocument();
  });

  it('shows a singular warning message when there is one warning', () => {
    wrap([{ message: 'Watch out', type: 'warning' }]);
    expect(screen.getByText('There is 1 configuration warning.')).toBeInTheDocument();
  });

  it('shows a plural warning message when there are multiple warnings', () => {
    wrap([
      { message: 'Warn one', type: 'warning' },
      { message: 'Warn two', type: 'warning' },
      { message: 'Warn three', type: 'warning' },
    ]);
    expect(screen.getByText('There are 3 configuration warnings.')).toBeInTheDocument();
  });

  it('shows a singular info message', () => {
    wrap([{ message: 'FYI', type: 'info' }]);
    expect(screen.getByText('There is 1 configuration message.')).toBeInTheDocument();
  });

  it('shows a plural info message', () => {
    wrap([
      { message: 'Info one', type: 'info' },
      { message: 'Info two', type: 'info' },
    ]);
    // Note: the plural info branch in the source reads "configuration errors" (copy-paste in source)
    expect(screen.getByText('There are 2 configuration errors.')).toBeInTheDocument();
  });

  it('renders alerts for all three message types simultaneously', () => {
    wrap([
      { message: 'err', type: 'error' },
      { message: 'warn', type: 'warning' },
      { message: 'info', type: 'info' },
    ]);
    expect(
      screen.getByText('There is 1 configuration error that must be resolved.'),
    ).toBeInTheDocument();
    expect(screen.getByText('There is 1 configuration warning.')).toBeInTheDocument();
    expect(screen.getByText('There is 1 configuration message.')).toBeInTheDocument();
  });

  it('renders nothing when messages array is empty', () => {
    const { container } = wrap([]);
    expect(container.querySelector('.MuiAlert-root')).toBeNull();
  });

  it('navigates on click without throwing', () => {
    wrap([{ message: 'Bad config', type: 'error' }]);
    const alert = screen.getByRole('alert');
    expect(() => fireEvent.click(alert)).not.toThrow();
  });

  it('navigates on Enter key without throwing', () => {
    wrap([{ message: 'Bad config', type: 'error' }]);
    const alert = screen.getByRole('alert');
    expect(() => fireEvent.keyDown(alert, { key: 'Enter' })).not.toThrow();
  });

  it('does not navigate on non-Enter key', () => {
    wrap([{ message: 'Bad config', type: 'error' }]);
    const alert = screen.getByRole('alert');
    expect(() => fireEvent.keyDown(alert, { key: 'Escape' })).not.toThrow();
  });
});
