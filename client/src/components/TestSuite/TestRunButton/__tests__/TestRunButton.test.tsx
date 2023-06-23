import React from 'react';
import { BrowserRouter } from 'react-router-dom';
import { render, screen } from '@testing-library/react';
import { SnackbarProvider } from 'notistack';
import { vi } from 'vitest';
import { RunnableType } from '~/models/testSuiteModels';
import ThemeProvider from 'components/ThemeProvider';
import TestRunButton from '../TestRunButton';
import { mockedTestRunButtonData } from '../__mocked_data__/mockData';
import userEvent from '@testing-library/user-event';

describe('The TestRunButton Component', () => {
  it('renders TestRunButton for tests', () => {
    render(
      <BrowserRouter>
        <ThemeProvider>
          <SnackbarProvider>
            <TestRunButton
              runnable={mockedTestRunButtonData.test}
              runnableType={RunnableType.Test}
              runTests={mockedTestRunButtonData.runTests}
            />
          </SnackbarProvider>
        </ThemeProvider>
      </BrowserRouter>
    );

    const buttonElement = screen.getByTestId('runButton-mock-test-id');
    expect(buttonElement).toBeInTheDocument();
  });

  it('runs tests on button click', () => {
    const runTests = vi.spyOn(mockedTestRunButtonData, 'runTests');

    render(
      <BrowserRouter>
        <ThemeProvider>
          <SnackbarProvider>
            <TestRunButton
              runnable={mockedTestRunButtonData.test}
              runnableType={RunnableType.Test}
              runTests={mockedTestRunButtonData.runTests}
            />
          </SnackbarProvider>
        </ThemeProvider>
      </BrowserRouter>
    );

    const buttonElement = screen.getByTestId('runButton-mock-test-id');
    userEvent.click(buttonElement);
    expect(runTests).toBeCalledTimes(1);
  });

  it('renders TestRunButton for test groups', () => {
    render(
      <BrowserRouter>
        <ThemeProvider>
          <SnackbarProvider>
            <TestRunButton
              runnable={mockedTestRunButtonData.testGroup}
              runnableType={RunnableType.TestGroup}
              runTests={mockedTestRunButtonData.runTests}
            />
          </SnackbarProvider>
        </ThemeProvider>
      </BrowserRouter>
    );

    const buttonElement = screen.getByTestId('runButton-mock-test-group-id');
    expect(buttonElement).toBeInTheDocument();
  });

  it('runs test group on button click', () => {
    const runTests = vi.spyOn(mockedTestRunButtonData, 'runTests');

    render(
      <BrowserRouter>
        <ThemeProvider>
          <SnackbarProvider>
            <TestRunButton
              runnable={mockedTestRunButtonData.testGroup}
              runnableType={RunnableType.TestGroup}
              runTests={mockedTestRunButtonData.runTests}
            />
          </SnackbarProvider>
        </ThemeProvider>
      </BrowserRouter>
    );

    const buttonElement = screen.getByTestId('runButton-mock-test-group-id');
    userEvent.click(buttonElement);
    expect(runTests).toBeCalledTimes(1);
  });
});
