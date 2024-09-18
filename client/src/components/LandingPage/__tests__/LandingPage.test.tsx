import React from 'react';
import { BrowserRouter } from 'react-router-dom';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { expect, test, vi } from 'vitest';
import { SnackbarProvider } from 'notistack';
import * as testSessionApi from '~/api/TestSessionApi';
import ThemeProvider from '~/components/ThemeProvider';
import LandingPage from '~/components/LandingPage/LandingPage';
import { mockedTestSuitesReturnValue } from '../__mocked_data__/mockData';
import { singleTestSuite, testSession } from '~/components/App/__mocked_data__/mockData';

test('renders Inferno Landing Page', () => {
  const testSuites = mockedTestSuitesReturnValue;

  render(
    <BrowserRouter>
      <ThemeProvider>
        <SnackbarProvider>
          <LandingPage testSuites={testSuites} />
        </SnackbarProvider>
      </ThemeProvider>
    </BrowserRouter>,
  );

  const headerElements = screen.getAllByRole('heading');
  expect(headerElements[0]).toHaveTextContent('FHIR Testing with Inferno');
});

test('Start Testing button should be disabled when test suite is not selected', () => {
  const testSuites = mockedTestSuitesReturnValue;

  render(
    <BrowserRouter>
      <ThemeProvider>
        <SnackbarProvider>
          <LandingPage testSuites={testSuites} />
        </SnackbarProvider>
      </ThemeProvider>
    </BrowserRouter>,
  );

  const buttonElement = screen.getByTestId('go-button');
  expect(buttonElement).toBeDisabled();
});

test('should enable Start Testing when test suite is selected', async () => {
  const testSuites = mockedTestSuitesReturnValue;

  render(
    <BrowserRouter>
      <ThemeProvider>
        <SnackbarProvider>
          <LandingPage testSuites={testSuites} />
        </SnackbarProvider>
      </ThemeProvider>
    </BrowserRouter>,
  );

  const testSuiteElement = screen.getAllByTestId('list-option')[0];
  const buttonElement = screen.getByTestId('go-button');

  await userEvent.click(testSuiteElement);
  expect(testSuiteElement).toHaveFocus();
  expect(buttonElement).toBeEnabled();
});

test('sets the Test Session if there is a single Test Suite', () => {
  const postTestSessions = vi.spyOn(testSessionApi, 'postTestSessions');
  postTestSessions.mockResolvedValue(testSession);

  render(
    <BrowserRouter>
      <ThemeProvider>
        <SnackbarProvider>
          <LandingPage testSuites={singleTestSuite} />
        </SnackbarProvider>
      </ThemeProvider>
    </BrowserRouter>,
  );
  expect(postTestSessions).toBeCalledTimes(1);
});
