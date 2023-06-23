import React from 'react';
import { BrowserRouter } from 'react-router-dom';
import { render, screen } from '@testing-library/react';
import { SnackbarProvider } from 'notistack';
import ThemeProvider from 'components/ThemeProvider';
import TestSessionComponent from '../TestSession';
import { mockedTestSession, mockedResultsList } from '../__mocked_data__/mockData';

test('renders TestSession', () => {
  let drawerOpen = true;

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
    </BrowserRouter>
  );

  const testSessionTitleComponentList = screen.getAllByTestId('navigable-group-item');
  testSessionTitleComponentList.forEach((testSessionTitleComponent, i) => {
    const testGroups = mockedTestSession.test_suite.test_groups || [];
    const testGroupTitle = testGroups[i].title || undefined;
    expect(testSessionTitleComponent).toHaveAccessibleName(testGroupTitle);
  });
});
