import React from 'react';
import { Router } from 'react-router';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import ThemeProvider from 'components/ThemeProvider';
import { createMemoryHistory } from 'history';
import { TestSuite } from 'models/testSuiteModels';
import LandingPage from '../LandingPage';

test('renders Inferno Landing Page', () => {
  const testSuites = [] as TestSuite[];

  render(
    <ThemeProvider>
      <LandingPage testSuites={testSuites} />
    </ThemeProvider>
  );

  const headerElements = screen.getAllByRole('heading');
  expect(headerElements[0]).toHaveTextContent('FHIR Testing with Inferno');
});

test('Start Testing button should be disabled when test suite is not selected', () => {
  const testSuites = [] as TestSuite[];

  render(
    <ThemeProvider>
      <LandingPage testSuites={testSuites} />
    </ThemeProvider>
  );

  const buttonElement = screen.getByRole('button');
  expect(buttonElement).toBeDisabled();
});

test('should enable Start Testing when test suite is selected', () => {
  const history = createMemoryHistory();
  const testSuites = [{ title: 'title', id: 'id' }] as TestSuite[];

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
