import React from 'react';
import { MemoryRouter } from 'react-router-dom';
import { render } from '@testing-library/react';
import { SnackbarProvider } from 'notistack';
import ThemeProvider from 'components/ThemeProvider';
import AppSkeleton from 'components/Skeletons/AppSkeleton';
import DrawerSkeleton from 'components/Skeletons/DrawerSkeleton';
import FooterSkeleton from 'components/Skeletons/FooterSkeleton';
import HeaderSkeleton from 'components/Skeletons/HeaderSkeleton';
import TestSessionSkeleton from 'components/Skeletons/TestSessionSkeleton';

describe('Skeleton Components', () => {
  it('renders App Skeleton', () => {
    render(
      <MemoryRouter>
        <ThemeProvider>
          <SnackbarProvider>
            <AppSkeleton />
          </SnackbarProvider>
        </ThemeProvider>
      </MemoryRouter>
    );
  });

  it('renders Drawer Skeleton', () => {
    render(
      <MemoryRouter>
        <ThemeProvider>
          <SnackbarProvider>
            <DrawerSkeleton />
          </SnackbarProvider>
        </ThemeProvider>
      </MemoryRouter>
    );
  });

  it('renders Footer Skeleton', () => {
    render(
      <MemoryRouter>
        <ThemeProvider>
          <SnackbarProvider>
            <FooterSkeleton />
          </SnackbarProvider>
        </ThemeProvider>
      </MemoryRouter>
    );
  });

  it('renders Header Skeleton', () => {
    render(
      <MemoryRouter>
        <ThemeProvider>
          <SnackbarProvider>
            <HeaderSkeleton />
          </SnackbarProvider>
        </ThemeProvider>
      </MemoryRouter>
    );
  });

  it('renders TestSessionSkeleton Skeleton', () => {
    render(
      <MemoryRouter>
        <ThemeProvider>
          <SnackbarProvider>
            <TestSessionSkeleton />
          </SnackbarProvider>
        </ThemeProvider>
      </MemoryRouter>
    );
  });
});
