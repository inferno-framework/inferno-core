import React, { act } from 'react';
import { BrowserRouter } from 'react-router';
import { SnackbarProvider } from 'notistack';
import { render, screen, waitFor } from '@testing-library/react';
import { describe, expect, it, vi } from 'vitest';
import * as versionsApi from '~/api/VersionsApi';
import ThemeProvider from 'components/ThemeProvider';
import TestSessionComponent from '../TestSession';
import TestSessionWrapper from '../TestSessionWrapper';
import { mockedTestSession, mockedResultsList } from '../__mocked_data__/mockData';

describe('The TestSession Component', () => {
  it('renders TestSessionWrapper', async () => {
    const getCoreVersion = vi.spyOn(versionsApi, 'getCoreVersion');
    getCoreVersion.mockResolvedValue('1.2.34');

    await act(() =>
      render(
        <BrowserRouter>
          <ThemeProvider>
            <SnackbarProvider>
              <TestSessionWrapper />
            </SnackbarProvider>
          </ThemeProvider>
        </BrowserRouter>,
      ),
    );

    await waitFor(() => {
      expect(getCoreVersion).toBeCalledTimes(1);
    });
  });

  it('renders TestSession', async () => {
    let drawerOpen = true;

    await act(() =>
      render(
        <BrowserRouter>
          <ThemeProvider>
            <SnackbarProvider>
              <TestSessionComponent
                testSession={mockedTestSession}
                previousResults={mockedResultsList}
                initialTestRun={null}
                sessionData={new Map()}
                setSessionData={() => {}}
                drawerOpen={drawerOpen}
                toggleDrawer={() => (drawerOpen = !drawerOpen)}
              />
            </SnackbarProvider>
          </ThemeProvider>
        </BrowserRouter>,
      ),
    );

    await waitFor(() => {
      const testSessionTitleComponentList = screen.getAllByTestId('navigable-group-item');
      testSessionTitleComponentList.forEach((testSessionTitleComponent, i) => {
        const testGroups = mockedTestSession.test_suite.test_groups || [];
        const testGroupTitle = testGroups[i].title || undefined;
        expect(testSessionTitleComponent).toHaveAccessibleName(testGroupTitle);
      });
    });
  });
});
