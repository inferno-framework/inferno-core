import React from 'react';
import { renderWithProviders, waitFor } from '~/test-utils';

import { beforeEach, describe, expect, it, vi } from 'vitest';

import App from '../App';
import * as testSuitesApi from '~/api/TestSuitesApi';
import { testSuites } from '../__mocked_data__/mockData';

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

  it('sets Test Suite state on mount', async () => {
    const getTestSuites = vi.spyOn(testSuitesApi, 'getTestSuites');
    getTestSuites.mockResolvedValue(testSuites);

    renderWithProviders(<App />, { noRouter: true });

    await waitFor(() => {
      expect(getTestSuites).toBeCalledTimes(1);
    });
  });

  it('handles test suite fetch error gracefully', async () => {
    const getTestSuites = vi.spyOn(testSuitesApi, 'getTestSuites');
    getTestSuites.mockRejectedValue(new Error('network error'));

    renderWithProviders(<App />, { noRouter: true });

    await waitFor(() => {
      expect(getTestSuites).toBeCalledTimes(1);
    });
  });
});
