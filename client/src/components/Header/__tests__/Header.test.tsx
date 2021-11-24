import React from 'react';
import { act } from 'react-dom/test-utils';
import { Router } from 'react-router';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import ThemeProvider from 'components/ThemeProvider';
import { createMemoryHistory } from 'history';
import Header from '../Header';

test('renders Inferno Header', () => {
  render(
    <ThemeProvider>
      <Header />
    </ThemeProvider>
  );

  const logoElement = screen.getByRole('img');
  const logoPath = '../../../images/inferno_logo.png';

  expect(logoElement).toHaveAttribute('alt', 'inferno logo');
  console.log(logoElement);

  expect(logoElement).toHaveAttribute('src');
  // expect(logoElement.getAttribute('src')).toHaveAttribute('src', logoPath);
  // TODO: Broken test
});

test('should navigate home when logo is clicked', () => {
  const history = createMemoryHistory({ initialEntries: ['/test_sessions/:test_session_id'] });

  render(
    <Router history={history}>
      <ThemeProvider>
        <Header />
      </ThemeProvider>
    </Router>
  );

  const buttonElement = screen.getByRole('button');

  act(() => {
    userEvent.click(buttonElement);
  });

  expect(history.location.pathname).toBe('/');
});
