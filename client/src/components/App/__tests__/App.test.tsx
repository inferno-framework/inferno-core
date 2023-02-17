import React from 'react';
import { render, screen } from '@testing-library/react';
import { SnackbarProvider } from 'notistack';

import App from '../App';
import * as testSuitesApi from '~/api/TestSuitesApi';
import * as testSessionApi from '~/api/TestSessionApi';
import { testSuites, singleTestSuite, testSession } from '../__mocked_data__/mockData';

import { vi } from 'vitest';

// Mock out a complex child component, react-testing-library advises
// against this but we are in the App component, so maybe make an exception?
vi.mock('~/components/TestSuite/TestSessionWrapper', () => ({
  default: vi.fn(() => {
    return <div>mock</div>;
  }),
}));

describe('The App Root Component', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('sets Test Suite state on mount', () => {
    const getTestSuites = vi.spyOn(testSuitesApi, 'getTestSuites');
    getTestSuites.mockResolvedValue(testSuites);

    render(
      <SnackbarProvider>
        <App />
      </SnackbarProvider>
    );

    expect(getTestSuites).toBeCalledTimes(1);
  });

  it('sets the Test Session if there is a single Test Suite', async () => {
    const getTestSuites = vi.spyOn(testSuitesApi, 'getTestSuites');
    getTestSuites.mockResolvedValue(singleTestSuite);

    const postTestSessions = vi.spyOn(testSessionApi, 'postTestSessions');
    postTestSessions.mockResolvedValue(testSession);
    postTestSessions.mockRejectedValue(new Error('Error while creating test session'));

    render(
      <SnackbarProvider>
        <App />
      </SnackbarProvider>
    );

    // We have to wait for something to load so we don't get act()
    // warnings.  The only thing rendered by App is children components.
    // So await for those to be done with side effects (hooks).
    await screen.findByText('Suite One');
    expect(postTestSessions).toBeCalledTimes(1);
  });
});
