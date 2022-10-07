import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import ThemeProvider from 'components/ThemeProvider';
import Header from '../Header';

// this testing helper is needed to test react hooks outside of render
import { renderHook, act } from '@testing-library/react-hooks';
import { useAppStore } from '~/store/app';

// boilerplate for mocking zustand which uses hooks outside of a component
beforeEach(() => {
  const { result } = renderHook(() => useAppStore((state) => state));

  act(() => {
    result.current.windowIsSmall = true;
  });
});

test('renders wide screen Inferno Header', () => {
  let drawerOpen = true;

  render(
    <ThemeProvider>
      <Header
        suiteTitle="Suite Title"
        drawerOpen={drawerOpen}
        toggleDrawer={() => (drawerOpen = !drawerOpen)}
      />
    </ThemeProvider>
  );

  const logoElement = screen.getByRole('img');
  expect(logoElement).toHaveAttribute('alt', 'Inferno logo');

  const titleElement = screen.getAllByRole('heading')[0];
  expect(titleElement).toHaveTextContent('Suite Title');
});

test('renders narrow screen Inferno Header', () => {
  let drawerOpen = false;

  render(
    <ThemeProvider>
      <Header
        suiteTitle="Suite Title"
        drawerOpen={drawerOpen}
        toggleDrawer={() => (drawerOpen = !drawerOpen)}
      />
    </ThemeProvider>
  );

  const logoElement = screen.getByRole('img');
  expect(logoElement).toHaveAttribute('alt', 'Inferno logo');

  // test icon drawer control
  expect(drawerOpen).toBe(false);
  userEvent.click(logoElement);
  expect(drawerOpen).toBe(true);
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
