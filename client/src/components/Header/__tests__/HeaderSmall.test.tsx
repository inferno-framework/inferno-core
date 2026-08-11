import React from 'react';
import { renderWithMemoryRouter, renderHook, screen } from '~/test-utils';
import Header from '../Header';

import { useAppStore } from '~/store/app';
import { beforeEach, expect, test } from 'vitest';

// boilerplate for mocking zustand which uses hooks outside of a component
beforeEach(() => {
  const { result } = renderHook(() => useAppStore((state) => state));
  result.current.windowIsSmall = true;
});

test('renders narrow screen Inferno Header', async () => {
  let drawerOpen = false;

  const { user } = renderWithMemoryRouter(
    <Header
      suiteTitle="Suite Title"
      drawerOpen={drawerOpen}
      toggleDrawer={() => (drawerOpen = !drawerOpen)}
    />,
  );

  const buttonElement = screen.getAllByRole('button')[0];
  expect(buttonElement).toHaveAttribute('aria-label', 'menu');

  // test icon drawer control
  expect(drawerOpen).toBe(false);
  await user.click(buttonElement);
  expect(drawerOpen).toBe(true);
});
