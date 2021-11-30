import React from 'react';
import { Router } from 'react-router';
import { render, screen } from '@testing-library/react';
import { createMemoryHistory } from 'history';
import ThemeProvider from 'components/ThemeProvider';
import TestSessionComponent from '../TestSession';
import { mockedTestSession, mockedResultsList } from '../__mocked_data__/mockData';

test('Test session renders', () => {
  const history = createMemoryHistory();

  render(
    <Router history={history}>
      <ThemeProvider>
        <TestSessionComponent
          testSession={mockedTestSession}
          previousResults={mockedResultsList}
          initialTestRun={null}
          initialSessionData={undefined}
        />
      </ThemeProvider>
    </Router>
  );

  const testSessionWrapperComponent = screen.getByRole('tree');
  expect(testSessionWrapperComponent).toBeInTheDocument();
});
