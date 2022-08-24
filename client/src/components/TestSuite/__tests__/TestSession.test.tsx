import React from 'react';
import { Router } from 'react-router';
import { render, screen } from '@testing-library/react';
import { createMemoryHistory } from 'history';
import ThemeProvider from 'components/ThemeProvider';
import TestSessionComponent from '../TestSession';
import { mockedTestSession, mockedResultsList } from '../__mocked_data__/mockData';

test('Test session renders', () => {
  const history = createMemoryHistory();
  let drawerOpen = true;

  render(
    <Router history={history}>
      <ThemeProvider>
        <TestSessionComponent
          testSession={mockedTestSession}
          previousResults={mockedResultsList}
          initialTestRun={null}
          sessionData={new Map()}
          setSessionData={() => {}}
          drawerOpen={drawerOpen}
          toggleDrawer={() => (drawerOpen = !drawerOpen)}
        />
      </ThemeProvider>
    </Router>
  );

  const testSessionTitleComponentList = screen.getAllByRole('link');
  testSessionTitleComponentList.forEach((testSessionTitleComponent, i) => {
    const testGroups = mockedTestSession.test_suite.test_groups || [];
    const testGroupTitle = testGroups[i].title || undefined;
    expect(testSessionTitleComponent).toHaveAccessibleName(testGroupTitle);
  });
});
