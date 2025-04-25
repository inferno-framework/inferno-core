import React from 'react';
import { render, renderHook, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import ThemeProvider from 'components/ThemeProvider';
import Header from '../Header';

import { MemoryRouter } from 'react-router';
import { useAppStore } from '~/store/app';
import { beforeEach, expect, test } from 'vitest';

// boilerplate for mocking zustand which uses hooks outside of a component
beforeEach(() => {
  const { result } = renderHook(() => useAppStore((state) => state));
  result.current.windowIsSmall = true;
});

test('renders narrow screen Inferno Header', async () => {
  let drawerOpen = false;

  render(
    <MemoryRouter>
      <ThemeProvider>
        <Header
          suiteTitle="Suite Title"
          drawerOpen={drawerOpen}
          toggleDrawer={() => (drawerOpen = !drawerOpen)}
        />
      </ThemeProvider>
    </MemoryRouter>,
  );

  const buttonElement = screen.getAllByRole('button')[0];
  expect(buttonElement).toHaveAttribute('aria-label', 'menu');

  // test icon drawer control
  expect(drawerOpen).toBe(false);
  await userEvent.click(buttonElement);
  expect(drawerOpen).toBe(true);
});
