import React, { act } from 'react';
import { MemoryRouter } from 'react-router';
import { render, renderHook, screen } from '@testing-library/react';
import { SnackbarProvider } from 'notistack';
import ThemeProvider from 'components/ThemeProvider';
import TestSessionComponent from '../TestSession';
import { mockedTestSession, mockedResultsList } from '../__mocked_data__/mockData';
import { useAppStore } from '~/store/app';
import { beforeEach, expect, test } from 'vitest';

// boilerplate for mocking zustand which uses hooks outside of a component
beforeEach(() => {
  const { result } = renderHook(() => useAppStore((state) => state));
  result.current.windowIsSmall = true;
});

test('renders narrow screen TestSession', async () => {
  let drawerOpen = false;

  await act(() =>
    render(
      <MemoryRouter>
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
      </MemoryRouter>,
    ),
  );

  const testSessionTitleComponentList = screen.getAllByTestId('navigable-group-item');
  testSessionTitleComponentList.forEach((testSessionTitleComponent, i) => {
    const testGroups = mockedTestSession.test_suite.test_groups || [];
    const testGroupTitle = testGroups[i].title || undefined;
    expect(testSessionTitleComponent).toHaveAccessibleName(testGroupTitle);
  });
});
