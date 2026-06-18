import React from 'react';
import { renderWithMemoryRouter, renderHook, screen } from '~/test-utils';
import Header from '../Header';

import { useAppStore } from '~/store/app';
import { beforeEach, expect, test } from 'vitest';

// boilerplate for mocking zustand which uses hooks outside of a component
beforeEach(() => {
  const { result } = renderHook(() => useAppStore((state) => state));
  result.current.windowIsSmall = false;
});

test('renders wide screen Inferno Header', () => {
  let drawerOpen = true;

  renderWithMemoryRouter(
    <Header
      suiteTitle="Suite Title"
      drawerOpen={drawerOpen}
      toggleDrawer={() => (drawerOpen = !drawerOpen)}
    />,
  );

  const logoElement = screen.getByRole('img');
  expect(logoElement).toHaveAttribute('alt', 'Inferno logo');

  const titleElement = screen.getAllByRole('heading')[0];
  expect(titleElement).toHaveTextContent('Suite Title');
});

test('clicking Help link opens HelpModal', async () => {
  const { user } = renderWithMemoryRouter(
    <Header suiteTitle="Suite Title" drawerOpen={false} toggleDrawer={() => {}} />,
  );

  const helpLink = screen.getByText('Help');
  await user.click(helpLink);

  expect(screen.getByTestId('HelpModal')).toBeVisible();
});
