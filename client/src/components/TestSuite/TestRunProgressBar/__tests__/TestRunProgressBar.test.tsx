import React from 'react';
import { BrowserRouter } from 'react-router-dom';
import { render, screen } from '@testing-library/react';
import { SnackbarProvider } from 'notistack';
import ThemeProvider from 'components/ThemeProvider';
import { mockedTestRun, getMockedResultsMap } from '../__mocked_data__/mockData';
import TestRunProgressBar from '../TestRunProgressBar';
import userEvent from '@testing-library/user-event';
import { describe, expect, test } from 'vitest';

describe('The TestRunProgressBar Component', () => {
  test('renders TestRunProgressBar', () => {
    let showProgressBar = true;
    let testRunCancelled = false;

    render(
      <BrowserRouter>
        <ThemeProvider>
          <SnackbarProvider>
            <TestRunProgressBar
              showProgressBar={showProgressBar}
              setShowProgressBar={() => (showProgressBar = !showProgressBar)}
              cancelled={testRunCancelled}
              cancelTestRun={() => (testRunCancelled = true)}
              duration={500}
              testRun={mockedTestRun}
              resultsMap={getMockedResultsMap()}
            />
          </SnackbarProvider>
        </ThemeProvider>
      </BrowserRouter>,
    );

    const progressBarElement = screen.getByTestId('progress-bar');
    expect(progressBarElement).toBeInTheDocument();
  });

  test('clicking Cancel cancels the test run', async () => {
    let showProgressBar = true;
    let testRunCancelled = false;

    render(
      <BrowserRouter>
        <ThemeProvider>
          <SnackbarProvider>
            <TestRunProgressBar
              showProgressBar={showProgressBar}
              setShowProgressBar={() => (showProgressBar = !showProgressBar)}
              cancelled={testRunCancelled}
              cancelTestRun={() => (testRunCancelled = true)}
              duration={500}
              testRun={mockedTestRun}
              resultsMap={getMockedResultsMap()}
            />
          </SnackbarProvider>
        </ThemeProvider>
      </BrowserRouter>,
    );

    const cancelButton = screen.getByRole('button');
    await userEvent.click(cancelButton);
    expect(testRunCancelled).toEqual(true);

    setTimeout(() => {
      const progressBarElement = screen.queryByTestId('progress-bar');
      expect(progressBarElement).toBeNull();
    }, 500);
  });
});
