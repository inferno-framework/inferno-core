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

  const buttonElement = screen.getAllByRole('button')[0];
  expect(buttonElement).toHaveAttribute('aria-label', 'menu');

  // test icon drawer control
  expect(drawerOpen).toBe(false);
  userEvent.click(buttonElement);
  expect(drawerOpen).toBe(true);
});