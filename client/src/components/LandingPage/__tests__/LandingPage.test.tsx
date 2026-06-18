import React from 'react';
import { renderWithProviders, screen, waitFor } from '~/test-utils';
import { expect, test, vi } from 'vitest';
import * as testSessionApi from '~/api/TestSessionApi';
import LandingPage from '~/components/LandingPage/LandingPage';
import { mockedTestSuitesReturnValue } from '../__mocked_data__/mockData';
import { singleTestSuite, testSession } from '~/components/App/__mocked_data__/mockData';

test('renders Inferno Landing Page', () => {
  const testSuites = mockedTestSuitesReturnValue;

  renderWithProviders(<LandingPage testSuites={testSuites} />);

  const headerElements = screen.getAllByRole('heading');
  expect(headerElements[0]).toHaveTextContent('FHIR Testing with Inferno');
});

test('Start Testing button should be disabled when test suite is not selected', () => {
  const testSuites = mockedTestSuitesReturnValue;

  renderWithProviders(<LandingPage testSuites={testSuites} />);

  const buttonElement = screen.getByTestId('go-button');
  expect(buttonElement).toBeDisabled();
});

test('should enable Start Testing when test suite is selected', async () => {
  const testSuites = mockedTestSuitesReturnValue;

  const { user } = renderWithProviders(<LandingPage testSuites={testSuites} />);

  const testSuiteElement = screen.getAllByTestId('list-option')[0];
  const buttonElement = screen.getByTestId('go-button');

  await user.click(testSuiteElement);
  expect(testSuiteElement).toHaveFocus();
  expect(buttonElement).toBeEnabled();
});

test('sets the Test Session if there is a single Test Suite', async () => {
  const postTestSessions = vi.spyOn(testSessionApi, 'postTestSessions');
  postTestSessions.mockResolvedValue(testSession);

  renderWithProviders(<LandingPage testSuites={singleTestSuite} />);

  await waitFor(() => {
    expect(postTestSessions).toBeCalledTimes(1);
  });
});

test('shows error snackbar when test session creation fails', async () => {
  const postTestSessions = vi.spyOn(testSessionApi, 'postTestSessions');
  postTestSessions.mockRejectedValue(new Error('network error'));

  const { user } = renderWithProviders(<LandingPage testSuites={mockedTestSuitesReturnValue} />);

  const testSuiteElement = screen.getAllByTestId('list-option')[0];
  await user.click(testSuiteElement);

  const buttonElement = screen.getByTestId('go-button');
  await user.click(buttonElement);

  await waitFor(() => {
    expect(screen.getByText(/Error while creating test session/)).toBeInTheDocument();
  });
});
