import React from 'react';
import { render, screen } from '@testing-library/react';
import ThemeProvider from 'components/ThemeProvider';
import Header from '../Header';

test('renders Inferno Header', () => {
  render(
    <ThemeProvider>
      <Header suiteTitle="Suite Title" />
    </ThemeProvider>
  );

  const logoElement = screen.getByRole('img');
  expect(logoElement).toHaveAttribute('alt', 'inferno logo');
});

// Commenting out for now
// We need to refine how the header works
// test('should navigate home when logo is clicked', () => {
//   const history = createMemoryHistory({ initialEntries: ['/test_sessions/:test_session_id'] });

//   render(
//     <Router history={history}>
//       <ThemeProvider>
//         <Header />
//       </ThemeProvider>
//     </Router>
//   );

//   const linkElement = screen.getByRole('link');
//   userEvent.click(linkElement);
//   expect(history.location.pathname).toBe('/');
// });
