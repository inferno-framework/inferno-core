import React from 'react';
import { render } from '@testing-library/react';
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

  it('sets the Test Session if there is a single Test Suite', () => {
    const getTestSuites = vi.spyOn(testSuitesApi, 'getTestSuites');
    getTestSuites.mockResolvedValue(singleTestSuite);

    const postTestSessions = vi.spyOn(testSessionApi, 'postTestSessions');
    postTestSessions.mockResolvedValue(testSession);

    render(
      <SnackbarProvider>
        <App />
      </SnackbarProvider>
    );

    console.log('test');

    expect(getTestSuites).toBeCalledTimes(1);
    // expect(postTestSessions).toBeCalledTimes(1);
  });
});
