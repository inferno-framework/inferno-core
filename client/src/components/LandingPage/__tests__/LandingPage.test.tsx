import React from 'react';
import { BrowserRouter } from 'react-router-dom';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { SnackbarProvider } from 'notistack';
import ThemeProvider from 'components/ThemeProvider';
import LandingPage from '../LandingPage';
import { mockedTestSuitesReturnValue } from '../__mocked_data__/mockData';

test('renders Inferno Landing Page', () => {
  const testSuites = mockedTestSuitesReturnValue;

  render(
    <BrowserRouter>
      <ThemeProvider>
        <LandingPage testSuites={testSuites} />
      </ThemeProvider>
    </BrowserRouter>
  );

  const headerElements = screen.getAllByRole('heading');
  expect(headerElements[0]).toHaveTextContent('FHIR Testing with Inferno');
});

test('Start Testing button should be disabled when test suite is not selected', () => {
  const testSuites = mockedTestSuitesReturnValue;

  render(
    <BrowserRouter>
      <ThemeProvider>
        <LandingPage testSuites={testSuites} />
      </ThemeProvider>
    </BrowserRouter>
  );

  const buttonElement = screen.getByTestId('go-button');
  expect(buttonElement).toBeDisabled();
});

test('should enable Start Testing when test suite is selected', () => {
  const testSuites = mockedTestSuitesReturnValue;

  render(
    <BrowserRouter>
      <ThemeProvider>
        <SnackbarProvider>
          <LandingPage testSuites={testSuites} />
        </SnackbarProvider>
      </ThemeProvider>
    </BrowserRouter>
  );

  const testSuiteElement = screen.getAllByTestId('testing-suite-option')[0];
  const buttonElement = screen.getByTestId('go-button');

  userEvent.click(testSuiteElement);
  expect(testSuiteElement).toHaveFocus();
  expect(buttonElement).toBeEnabled();
});
