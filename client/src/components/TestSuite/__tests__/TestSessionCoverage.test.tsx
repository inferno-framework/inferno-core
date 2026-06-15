import React, { act } from 'react';
import { MemoryRouter } from 'react-router';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi, beforeEach, afterEach } from 'vitest';
import { SnackbarProvider } from 'notistack';
import ThemeProvider from 'components/ThemeProvider';
import TestSessionComponent from '../TestSession';
import { mockedTestSession } from '../__mocked_data__/mockData';
import * as RequirementsApi from '~/api/RequirementsApi';
import * as TestRunsApi from '~/api/TestRunsApi';
import { useAppStore } from '~/store/app';
import { useTestSessionStore } from '~/store/testSession';
import { Requirement, RunnableType, TestRun, TestSession } from '~/models/testSuiteModels';

// ─── shared mock data ────────────────────────────────────────────────────────

const doneTestRun: TestRun = {
  id: 'run-1',
  status: 'done',
  test_session_id: mockedTestSession.id,
  test_count: 22,
  results: [],
};

const runningTestRun: TestRun = {
  id: 'run-1',
  status: 'running',
  test_session_id: mockedTestSession.id,
  test_count: 22,
  results: [],
};

const waitingTestRun: TestRun = {
  id: 'run-1',
  status: 'waiting',
  test_session_id: mockedTestSession.id,
  test_count: 22,
  results: [
    {
      id: 'result-1',
      result: 'wait',
      test_id: 'demo-Group01-test1',
      test_run_id: 'run-1',
      test_session_id: mockedTestSession.id,
      updated_at: '2024-01-01T00:00:00Z',
      outputs: [],
    },
  ],
};

// Base expanded group — TestGroupListItem only renders the run button when expanded: true
const expandedGroup = {
  ...mockedTestSession.test_suite.test_groups![0],
  expanded: true,
};

// Session variant where the base group is expanded (run button visible)
const sessionWithExpandedGroup: TestSession = {
  ...mockedTestSession,
  test_suite: {
    ...mockedTestSession.test_suite,
    test_groups: [expandedGroup],
  },
};

// Session variant where the test group has a visible input (and is expanded)
const sessionWithInputGroup: TestSession = {
  ...mockedTestSession,
  test_suite: {
    ...mockedTestSession.test_suite,
    test_groups: [
      {
        ...expandedGroup,
        inputs: [{ name: 'server_url', title: 'Server URL', type: 'text' }],
      },
    ],
  },
};

// Session variant where all group inputs are hidden (and group is expanded)
const sessionWithHiddenInputGroup: TestSession = {
  ...mockedTestSession,
  test_suite: {
    ...mockedTestSession.test_suite,
    test_groups: [
      {
        ...expandedGroup,
        inputs: [{ name: 'server_url', hidden: true }],
      },
    ],
  },
};

// ─── render helper ───────────────────────────────────────────────────────────

async function renderTestSession(
  options: {
    hash?: string;
    initialTestRun?: TestRun | null;
    testSession?: TestSession;
    drawerOpen?: boolean;
  } = {},
) {
  const {
    hash = '',
    initialTestRun = null,
    testSession = mockedTestSession,
    drawerOpen = false,
  } = options;

  // First pass: synchronous render
  await act(async () => {
    render(
      <MemoryRouter initialEntries={[{ pathname: '/', hash }]}>
        <ThemeProvider>
          <SnackbarProvider>
            <TestSessionComponent
              testSession={testSession}
              previousResults={[]}
              initialTestRun={initialTestRun}
              sessionData={new Map()}
              setSessionData={() => {}}
              drawerOpen={drawerOpen}
              toggleDrawer={() => {}}
            />
          </SnackbarProvider>
        </ThemeProvider>
      </MemoryRouter>,
    );
  });
  // Second pass: flush async effects (fetchRequirements promise chain)
  await act(async () => {});
}

// ─── suite ───────────────────────────────────────────────────────────────────

describe('TestSession additional coverage', () => {
  beforeEach(() => {
    vi.spyOn(RequirementsApi, 'getTestSuiteRequirements').mockResolvedValue([]);
  });

  afterEach(async () => {
    // Flush any async state updates (fetchRequirements, polling) still pending after the test
    await act(async () => {});
    vi.restoreAllMocks();
    useAppStore.setState({ windowIsSmall: undefined });
    useTestSessionStore.setState({ readOnly: false, currentRunnables: {}, testRunId: undefined });
  });

  // ── renderView switch cases ─────────────────────────────────────────────

  it('renders TestSuiteReport for the report view', async () => {
    await renderTestSession({ hash: '#demo/report' });
    expect(screen.getByText('Demonstration Suite Report')).toBeInTheDocument();
  });

  it('renders ConfigMessagesDetailsPanel for the config view', async () => {
    await renderTestSession({ hash: '#demo/config' });
    // "Configuration Messages" also appears in the sidebar tree; use the unique tabs aria-label
    expect(screen.getByRole('tablist', { name: 'config-messages-tabs' })).toBeInTheDocument();
  });

  it('renders the default TestSuiteDetailsPanel for the run view', async () => {
    await renderTestSession({ hash: '#demo/run' });
    const groupItems = screen.getAllByTestId('navigable-group-item');
    expect(groupItems).toHaveLength(mockedTestSession.test_suite.test_groups!.length);
  });

  it('renders Requirements panel after requirements are fetched', async () => {
    const mockReqs: Requirement[] = [
      {
        id: 'req-1',
        requirement: 'SHALL do something',
        conformance: 'SHALL',
        actor: 'Client',
        conditionality: 'false',
        subrequirements: [],
      },
    ];
    vi.spyOn(RequirementsApi, 'getTestSuiteRequirements').mockResolvedValue(mockReqs);

    await renderTestSession({ hash: '#demo/requirements' });

    await waitFor(() => {
      expect(
        screen.getByText('Demonstration Suite Specification Requirements'),
      ).toBeInTheDocument();
    });
  });

  // ── fetchRequirements ───────────────────────────────────────────────────

  it('shows an error snackbar when fetching requirements fails', async () => {
    vi.spyOn(RequirementsApi, 'getTestSuiteRequirements').mockRejectedValue(
      new Error('Network error'),
    );

    await renderTestSession();

    await waitFor(() => {
      expect(
        screen.getByText(/Error fetching specification requirements/),
      ).toBeInTheDocument();
    });
  });

  // ── runTests dispatch ───────────────────────────────────────────────────

  it('calls postTestRun directly when the group has no inputs', async () => {
    const postSpy = vi.spyOn(TestRunsApi, 'postTestRun').mockResolvedValue(doneTestRun);
    vi.spyOn(TestRunsApi, 'getTestRunWithResults').mockResolvedValue(doneTestRun);

    await renderTestSession({ testSession: sessionWithExpandedGroup });

    // Wrap in act(async) so React 18 flushes the full createTestRun.then() + poll chain
    await act(async () => {
      await userEvent.click(screen.getByTestId('runButton-demo-Group01'));
    });

    expect(postSpy).toHaveBeenCalledWith(
      mockedTestSession.id,
      RunnableType.TestGroup,
      'demo-Group01',
      [],
    );
  });

  it('opens InputsModal instead of running when the group has visible inputs', async () => {
    const postSpy = vi.spyOn(TestRunsApi, 'postTestRun');

    await renderTestSession({ testSession: sessionWithInputGroup });

    await act(async () => {
      await userEvent.click(screen.getByTestId('runButton-demo-Group01'));
    });

    expect(screen.getByRole('dialog')).toBeInTheDocument();
    // postTestRun should NOT have been called — modal requires explicit submission
    expect(postSpy).not.toHaveBeenCalled();
  });

  it('calls postTestRun directly when all inputs are hidden', async () => {
    const postSpy = vi.spyOn(TestRunsApi, 'postTestRun').mockResolvedValue(doneTestRun);
    vi.spyOn(TestRunsApi, 'getTestRunWithResults').mockResolvedValue(doneTestRun);

    await renderTestSession({ testSession: sessionWithHiddenInputGroup });

    await act(async () => {
      await userEvent.click(screen.getByTestId('runButton-demo-Group01'));
    });

    expect(postSpy).toHaveBeenCalledWith(
      mockedTestSession.id,
      RunnableType.TestGroup,
      'demo-Group01',
      expect.arrayContaining([expect.objectContaining({ name: 'server_url' })]),
    );
  });

  it('opens InputsModal in readOnly mode when the group has visible inputs', async () => {
    useTestSessionStore.setState({ readOnly: true });

    await renderTestSession({ testSession: sessionWithInputGroup });

    await act(async () => {
      await userEvent.click(screen.getByTestId('runButton-demo-Group01'));
    });

    expect(screen.getByRole('dialog')).toBeInTheDocument();
  });

  // ── createTestRun error handling ────────────────────────────────────────

  it('shows an error snackbar when postTestRun fails', async () => {
    vi.spyOn(TestRunsApi, 'postTestRun').mockRejectedValue(new Error('Server error'));

    await renderTestSession({ testSession: sessionWithExpandedGroup });

    await act(async () => {
      await userEvent.click(screen.getByTestId('runButton-demo-Group01'));
    });

    await waitFor(() => {
      expect(screen.getByText(/Error while running test/)).toBeInTheDocument();
    });
  });

  // ── cancelTestRun ───────────────────────────────────────────────────────

  it('calls deleteTestRun when the cancel button is clicked', async () => {
    const deleteSpy = vi.spyOn(TestRunsApi, 'deleteTestRun').mockResolvedValue(new Response());
    // Return running once so the progress bar stays active after the first poll
    vi.spyOn(TestRunsApi, 'getTestRunWithResults')
      .mockResolvedValueOnce(runningTestRun)
      .mockResolvedValue(doneTestRun);

    await renderTestSession({ initialTestRun: runningTestRun });

    await waitFor(() => {
      // Cancel button is enabled when status is 'running'
      expect(screen.getByRole('button', { name: /cancel/i })).not.toBeDisabled();
    });

    // Wrap in act(async) so setTestRunCancelled(true) from deleteTestRun.then() is within act()
    await act(async () => {
      await userEvent.click(screen.getByRole('button', { name: /cancel/i }));
    });

    expect(deleteSpy).toHaveBeenCalledWith(runningTestRun.id);
  });

  it('shows an error snackbar when deleteTestRun fails', async () => {
    vi.spyOn(TestRunsApi, 'deleteTestRun').mockRejectedValue(new Error('Delete failed'));
    vi.spyOn(TestRunsApi, 'getTestRunWithResults')
      .mockResolvedValueOnce(runningTestRun)
      .mockResolvedValue(doneTestRun);

    await renderTestSession({ initialTestRun: runningTestRun });

    await waitFor(() => {
      expect(screen.getByRole('button', { name: /cancel/i })).not.toBeDisabled();
    });

    await act(async () => {
      await userEvent.click(screen.getByRole('button', { name: /cancel/i }));
    });

    await waitFor(() => {
      expect(screen.getByText(/Error while cancelling test run/)).toBeInTheDocument();
    });
  });

  // ── initialTestRun / polling ────────────────────────────────────────────

  it('shows the progress bar and starts polling when initialTestRun is in progress', async () => {
    // Return running once so the progress bar is still visible after the first poll
    const pollSpy = vi.spyOn(TestRunsApi, 'getTestRunWithResults')
      .mockResolvedValueOnce(runningTestRun)
      .mockResolvedValue(doneTestRun);

    await renderTestSession({ initialTestRun: runningTestRun });

    // Progress bar should appear immediately because initialTestRun is running
    expect(screen.getByTestId('progress-bar')).toBeInTheDocument();

    await waitFor(() => {
      // runningTestRun has no results so the after param is undefined on the first call
      expect(pollSpy).toHaveBeenCalledWith(runningTestRun.id, undefined);
    });
  });

  it('uses the most recent result timestamp as the polling after param', async () => {
    const runWithResults: TestRun = {
      ...runningTestRun,
      results: [
        {
          id: 'r1',
          result: 'pass',
          test_id: 'test-1',
          test_run_id: 'run-1',
          test_session_id: mockedTestSession.id,
          updated_at: '2024-06-01T12:00:00Z',
          outputs: [],
        },
      ],
    };
    const pollSpy = vi
      .spyOn(TestRunsApi, 'getTestRunWithResults')
      .mockResolvedValueOnce(runWithResults)
      .mockResolvedValue(doneTestRun);

    await renderTestSession({ initialTestRun: runningTestRun });

    await waitFor(() => {
      // Second polling call should use the result's updated_at as the after param
      expect(pollSpy).toHaveBeenCalledWith(runningTestRun.id, '2024-06-01T12:00:00Z');
    });
  });

  it('shows an error snackbar when polling fails', async () => {
    vi.spyOn(TestRunsApi, 'getTestRunWithResults').mockRejectedValue(new Error('Poll error'));

    await renderTestSession({ initialTestRun: runningTestRun });

    await waitFor(() => {
      expect(screen.getByText(/Error while getting test run/)).toBeInTheDocument();
    });
  });

  // ── windowIsSmall / SwipeableDrawer branch ──────────────────────────────

  it('renders the suite navigation tree via SwipeableDrawer when windowIsSmall', async () => {
    useAppStore.setState({ windowIsSmall: true });

    await renderTestSession({ drawerOpen: true });

    // The TestSuiteTree content should still be accessible via keepMounted
    await waitFor(() => {
      expect(screen.getAllByTestId('navigable-group-item')).toHaveLength(
        mockedTestSession.test_suite.test_groups!.length,
      );
    });
  });

  // ── waitingTestId effect → ActionModal ─────────────────────────────────

  it('shows ActionModal when a test run enters waiting status', async () => {
    vi.spyOn(TestRunsApi, 'getTestRunWithResults').mockResolvedValue(waitingTestRun);

    await renderTestSession({ initialTestRun: waitingTestRun });

    await waitFor(() => {
      expect(screen.getByRole('dialog')).toBeInTheDocument();
    });
  });
});
