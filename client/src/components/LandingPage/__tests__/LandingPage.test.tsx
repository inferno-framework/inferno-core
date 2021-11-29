import React from 'react';
import { Router } from 'react-router';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import ThemeProvider from 'components/ThemeProvider';
import { createMemoryHistory } from 'history';
import LandingPage from '../LandingPage';
import { mockedTestSuitesReturnValue } from '../__mocked_data__/mockData';

test('renders Inferno Landing Page', () => {
  const testSuites = mockedTestSuitesReturnValue;

  render(
    <ThemeProvider>
      <LandingPage testSuites={testSuites} />
    </ThemeProvider>
  );

  const headerElements = screen.getAllByRole('heading');
  expect(headerElements[0]).toHaveTextContent('FHIR Testing with Inferno');
});

test('Start Testing button should be disabled when test suite is not selected', () => {
  const testSuites = mockedTestSuitesReturnValue;

  render(
    <ThemeProvider>
      <LandingPage testSuites={testSuites} />
    </ThemeProvider>
  );

  const buttonElement = screen.getByTestId('go-button');
  expect(buttonElement).toBeDisabled();
});

test('should enable Start Testing when test suite is selected', () => {
  const history = createMemoryHistory();
  const testSuites = mockedTestSuitesReturnValue;

  render(
    <Router history={history}>
      <ThemeProvider>
        <LandingPage testSuites={testSuites} />
      </ThemeProvider>
    </Router>
  );

  const testSuiteElement = screen.getAllByTestId('testing-suite-option')[0];
  const buttonElement = screen.getByTestId('go-button');

  userEvent.click(testSuiteElement);
  expect(testSuiteElement).toHaveFocus();
  expect(buttonElement).toBeEnabled();
});
