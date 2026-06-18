import React, { act } from 'react';
import { MemoryRouter, Route, Routes } from 'react-router';
import { renderWithProviders, screen, waitFor } from '~/test-utils';
import { describe, expect, it, vi, beforeEach, afterEach } from 'vitest';
import SuiteOptionsPage from '../SuiteOptionsPage';
import * as TestSessionApi from '~/api/TestSessionApi';
import { TestSuite } from '~/models/testSuiteModels';

const mockCreatedSession = {
  id: 'new-session',
  test_suite_id: 'suite-1',
  test_suite: { id: 'suite-1', title: 'Suite One', inputs: [] },
};

// SuiteOptionsPage calls useParams(), so it must be rendered inside a Route that
// matches a path with a :test_suite_id param. We pass the MemoryRouter+Routes tree
// to renderWithProviders with noRouter:true so ThemeProvider/SnackbarProvider are
// still provided by the shared utility.
function wrapWithRouter(testSuite?: TestSuite) {
  return renderWithProviders(
    <MemoryRouter initialEntries={['/suite-1']}>
      <Routes>
        <Route path="/:test_suite_id" element={<SuiteOptionsPage testSuite={testSuite} />} />
      </Routes>
    </MemoryRouter>,
    { noRouter: true },
  );
}

describe('SuiteOptionsPage', () => {
  beforeEach(() => {
    // jsdom doesn't implement window.location.href navigation;
    // stub it to suppress "not implemented" errors
    vi.stubGlobal('location', { href: '', origin: 'http://localhost' });
  });

  afterEach(async () => {
    // Flush navigate() router state update that fires after session creation
    await act(async () => {});
    vi.unstubAllGlobals();
  });

  it('auto-creates a session when testSuite has no summary and no options', async () => {
    const postSpy = vi
      .spyOn(TestSessionApi, 'postTestSessions')
      .mockResolvedValue(mockCreatedSession);
    const suite: TestSuite = { id: 'suite-1', title: 'Suite One', inputs: [] };

    await act(() => wrapWithRouter(suite));

    await waitFor(() => expect(postSpy).toHaveBeenCalledTimes(1));
    expect(postSpy).toHaveBeenCalledWith('suite-1', null, null);
  });

  it('auto-creates a session when suite_options is an empty array', async () => {
    const postSpy = vi
      .spyOn(TestSessionApi, 'postTestSessions')
      .mockResolvedValue(mockCreatedSession);
    const suite: TestSuite = {
      id: 'suite-1',
      title: 'Suite One',
      inputs: [],
      suite_options: [],
    };

    await act(() => wrapWithRouter(suite));

    await waitFor(() => expect(postSpy).toHaveBeenCalledTimes(1));
  });

  it('shows the page title when testSuite has a suite_summary', async () => {
    const suite: TestSuite = {
      id: 'suite-1',
      title: 'Suite One',
      inputs: [],
      suite_summary: 'This suite validates FHIR resources.',
    };

    await act(() => wrapWithRouter(suite));

    expect(screen.getByRole('heading', { name: 'SUITE ONE' })).toBeInTheDocument();
    expect(screen.getByText('This suite validates FHIR resources.')).toBeInTheDocument();
  });

  it('shows the page title when testSuite has suite_options', async () => {
    const suite: TestSuite = {
      id: 'suite-1',
      title: 'Suite One',
      inputs: [],
      suite_options: [
        {
          id: 'opt-1',
          title: 'Option One',
          list_options: [{ label: 'Choice A', id: 'a', value: 'a' }],
        },
      ],
    };

    await act(() => wrapWithRouter(suite));

    expect(screen.getByRole('heading', { name: 'SUITE ONE' })).toBeInTheDocument();
  });

  it('shows an error snackbar when session creation fails', async () => {
    vi.spyOn(TestSessionApi, 'postTestSessions').mockRejectedValue(new Error('Server unavailable'));
    const suite: TestSuite = { id: 'suite-1', title: 'Suite One', inputs: [] };

    await act(() => wrapWithRouter(suite));

    await waitFor(() => {
      expect(screen.getByText(/Error while creating test session/)).toBeInTheDocument();
    });
  });

  it('does not show the page body when testSuite is undefined', async () => {
    await act(() => wrapWithRouter(undefined));
    expect(screen.queryByText('SUITE ONE')).not.toBeInTheDocument();
  });
});
