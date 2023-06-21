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

describe('The App Root Component', () => {
  it('renders TestRunButton for tests', () => {
    render(
      <BrowserRouter>
        <ThemeProvider>
          <SnackbarProvider>
            <TestRunButton
              runnable={mockedTestRunButtonData.mockedTest}
              runnableType={RunnableType.Test}
              runTests={mockedTestRunButtonData.mockedRunTests}
            />
          </SnackbarProvider>
        </ThemeProvider>
      </BrowserRouter>
    );

    const buttonElement = screen.getByTestId('runButton-mock-test-id');
    expect(buttonElement).toBeInTheDocument();
  });

  it('runs tests on button click', () => {
    const runTests = vi.spyOn(mockedTestRunButtonData, 'mockedRunTests');

    render(
      <BrowserRouter>
        <ThemeProvider>
          <SnackbarProvider>
            <TestRunButton
              runnable={mockedTestRunButtonData.mockedTest}
              runnableType={RunnableType.Test}
              runTests={mockedTestRunButtonData.mockedRunTests}
            />
          </SnackbarProvider>
        </ThemeProvider>
      </BrowserRouter>
    );

    const buttonElement = screen.getByTestId('runButton-mock-test-id');
    userEvent.click(buttonElement);
    expect(runTests).toBeCalledTimes(1);
  });
});
