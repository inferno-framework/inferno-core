import React from 'react';
import { render, screen } from '@testing-library/react';
import ThemeProvider from 'components/ThemeProvider';
import Header from '../Header';

// this testing helper is needed to test react hooks outside of render
import { renderHook, act } from '@testing-library/react-hooks';
import { useAppStore } from '~/store/app';

// boilerplate for mocking zustand which uses hooks outside of a component
beforeEach(() => {
  const { result } = renderHook(() => useAppStore((state) => state));

  act(() => {
    result.current.windowIsSmall = false;
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
