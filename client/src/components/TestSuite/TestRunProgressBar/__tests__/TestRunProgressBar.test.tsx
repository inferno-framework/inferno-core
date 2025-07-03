import React from 'react';
import { BrowserRouter } from 'react-router';
import { render, screen } from '@testing-library/react';
import { SnackbarProvider } from 'notistack';
import ThemeProvider from 'components/ThemeProvider';
import { mockedTestRun, getMockedResultsMap } from '../__mocked_data__/mockData';
import TestRunProgressBar from '../TestRunProgressBar';
import userEvent from '@testing-library/user-event';
import { describe, expect, it } from 'vitest';

describe('The TestRunProgressBar Component', () => {
  it('renders TestRunProgressBar', () => {
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

  it('clicking Cancel cancels the test run', async () => {
    let showProgressBar = true;
    let testRunCancelled = false;
    const setShowProgressBar = (toggleValue: boolean) => (showProgressBar = toggleValue);
    const cancelTestRun = () => {
      testRunCancelled = true;
      setShowProgressBar(false);
    };

    render(
      <BrowserRouter>
        <ThemeProvider>
          <SnackbarProvider>
            <TestRunProgressBar
              showProgressBar={showProgressBar}
              setShowProgressBar={setShowProgressBar}
              cancelled={testRunCancelled}
              cancelTestRun={cancelTestRun}
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
    expect(showProgressBar).toEqual(false);
  });
});
