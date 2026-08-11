import React, { ReactElement } from 'react';
import { render, RenderOptions, RenderResult } from '@testing-library/react';
import userEvent, { UserEvent } from '@testing-library/user-event';
import { BrowserRouter, MemoryRouter } from 'react-router';
import { SnackbarProvider } from 'notistack';
import ThemeProvider from 'components/ThemeProvider';

interface RenderWithProvidersResult extends RenderResult {
  user: UserEvent;
}

interface RenderOptions_ extends Omit<RenderOptions, 'wrapper'> {
  /** Set to true when the component under test renders its own Router. */
  noRouter?: boolean;
}

function Wrapper({ children }: { children: React.ReactNode }) {
  return (
    <BrowserRouter>
      <ThemeProvider>
        <SnackbarProvider>{children}</SnackbarProvider>
      </ThemeProvider>
    </BrowserRouter>
  );
}

function WrapperNoRouter({ children }: { children: React.ReactNode }) {
  return (
    <ThemeProvider>
      <SnackbarProvider>{children}</SnackbarProvider>
    </ThemeProvider>
  );
}

/**
 * Renders a component with BrowserRouter, ThemeProvider, and SnackbarProvider,
 * and returns a userEvent instance created via userEvent.setup() for correct
 * pointer event simulation under jsdom 25 + @testing-library/user-event v14.
 *
 * Pass `noRouter: true` when the component under test renders its own Router.
 */
export function renderWithProviders(
  ui: ReactElement,
  { noRouter, ...options }: RenderOptions_ = {},
): RenderWithProvidersResult {
  const user = userEvent.setup();
  const wrapper = noRouter ? WrapperNoRouter : Wrapper;
  return { user, ...render(ui, { wrapper, ...options }) };
}

/**
 * Like renderWithProviders but uses MemoryRouter so tests can control
 * the initial route path.
 */
export function renderWithMemoryRouter(
  ui: ReactElement,
  initialPath = '/',
  options?: Omit<RenderOptions, 'wrapper'>,
): RenderWithProvidersResult {
  const user = userEvent.setup();
  const MemoryWrapper = ({ children }: { children: React.ReactNode }) => (
    <MemoryRouter initialEntries={[initialPath]}>
      <ThemeProvider>
        <SnackbarProvider>{children}</SnackbarProvider>
      </ThemeProvider>
    </MemoryRouter>
  );
  return { user, ...render(ui, { wrapper: MemoryWrapper, ...options }) };
}

export * from '@testing-library/react';
