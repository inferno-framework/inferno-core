import React from 'react';
import { BrowserRouter } from 'react-router';
import { render, screen } from '@testing-library/react';
import { SnackbarProvider } from 'notistack';
import { describe, expect, it, vi } from 'vitest';
import { RunnableType } from '~/models/testSuiteModels';
import ThemeProvider from 'components/ThemeProvider';
import TestRunButton from '../TestRunButton';
import {
  mockedTestRunButtonData,
  mockedUnrunnableTestRunButtonData,
} from '../__mocked_data__/mockData';
import userEvent from '@testing-library/user-event';

describe('The TestRunButton Component', () => {
  it('does not render TestRunButton if test is not runnable', () => {
    render(
      <BrowserRouter>
        <ThemeProvider>
          <SnackbarProvider>
            <TestRunButton
              runnable={mockedUnrunnableTestRunButtonData.test}
              runnableType={RunnableType.Test}
              runTests={mockedUnrunnableTestRunButtonData.runTests}
            />
          </SnackbarProvider>
        </ThemeProvider>
      </BrowserRouter>,
    );

    const buttonElements = screen.queryAllByRole('button');
    expect(buttonElements).toHaveLength(0);
  });

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
      </BrowserRouter>,
    );

    const buttonElement = screen.queryByTestId(`runButton-${mockedTestRunButtonData.test.id}`);
    expect(buttonElement).toBeInTheDocument();
  });

  it('runs tests on button click', async () => {
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
      </BrowserRouter>,
    );

    const buttonElement = screen.getByTestId(`runButton-${mockedTestRunButtonData.test.id}`);
    await userEvent.click(buttonElement);
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
      </BrowserRouter>,
    );

    const buttonElement = screen.queryByTestId(`runButton-${mockedTestRunButtonData.testGroup.id}`);
    expect(buttonElement).toBeInTheDocument();
  });

  it('runs test group on button click', async () => {
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
      </BrowserRouter>,
    );

    const buttonElement = screen.getByTestId(`runButton-${mockedTestRunButtonData.testGroup.id}`);
    await userEvent.click(buttonElement);
    expect(runTests).toBeCalledTimes(1);
  });

  it('renders TestRunButton for test suites', () => {
    render(
      <BrowserRouter>
        <ThemeProvider>
          <SnackbarProvider>
            <TestRunButton
              runnable={mockedTestRunButtonData.testSuite}
              runnableType={RunnableType.TestSuite}
              runTests={mockedTestRunButtonData.runTests}
            />
          </SnackbarProvider>
        </ThemeProvider>
      </BrowserRouter>,
    );

    const buttonElement = screen.queryByTestId(`runButton-${mockedTestRunButtonData.testSuite.id}`);
    expect(buttonElement).toBeInTheDocument();
  });

  it('runs test suite on button click', async () => {
    const runTests = vi.spyOn(mockedTestRunButtonData, 'runTests');

    render(
      <BrowserRouter>
        <ThemeProvider>
          <SnackbarProvider>
            <TestRunButton
              runnable={mockedTestRunButtonData.testSuite}
              runnableType={RunnableType.TestSuite}
              runTests={mockedTestRunButtonData.runTests}
            />
          </SnackbarProvider>
        </ThemeProvider>
      </BrowserRouter>,
    );

    const buttonElement = screen.getByTestId(`runButton-${mockedTestRunButtonData.testSuite.id}`);
    await userEvent.click(buttonElement);
    expect(runTests).toBeCalledTimes(1);
  });
});
