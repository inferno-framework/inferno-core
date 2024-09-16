import React from 'react';
import { MemoryRouter } from 'react-router-dom';
import { render, screen } from '@testing-library/react';
import { SnackbarProvider } from 'notistack';
import ThemeProvider from 'components/ThemeProvider';
import AppSkeleton from 'components/Skeletons/AppSkeleton';
import DrawerSkeleton from 'components/Skeletons/DrawerSkeleton';
import FooterSkeleton from 'components/Skeletons/FooterSkeleton';
import HeaderSkeleton from 'components/Skeletons/HeaderSkeleton';
import LandingPageSkeleton from 'components/Skeletons/LandingPageSkeleton';
import SelectionSkeleton from 'components/Skeletons/SelectionSkeletion';
import SuiteOptionsPageSkeleton from 'components/Skeletons/SuiteOptionsPageSkeleton';
import TestSessionSkeleton from 'components/Skeletons/TestSessionSkeleton';
import { describe, expect, it } from 'vitest';

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

    const skeletonElement = screen.getByTestId('appSkeleton');
    expect(skeletonElement).toBeInTheDocument();
  });

  it('renders Landing Page Skeleton', () => {
    render(
      <MemoryRouter>
        <ThemeProvider>
          <SnackbarProvider>
            <LandingPageSkeleton />
          </SnackbarProvider>
        </ThemeProvider>
      </MemoryRouter>
    );

    const skeletonElement = screen.getByTestId('landingPageSkeleton');
    expect(skeletonElement).toBeInTheDocument();
  });

  it('renders Suite Options Page Skeleton', () => {
    render(
      <MemoryRouter>
        <ThemeProvider>
          <SnackbarProvider>
            <SuiteOptionsPageSkeleton />
          </SnackbarProvider>
        </ThemeProvider>
      </MemoryRouter>
    );

    const skeletonElement = screen.getByTestId('suiteOptionsPageSkeleton');
    expect(skeletonElement).toBeInTheDocument();
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

    const skeletonElement = screen.getByTestId('drawerSkeleton');
    expect(skeletonElement).toBeInTheDocument();
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

    const skeletonElement = screen.getByTestId('footerSkeleton');
    expect(skeletonElement).toBeInTheDocument();
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

    const skeletonElement = screen.getByTestId('headerSkeleton');
    expect(skeletonElement).toBeInTheDocument();
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

    const skeletonElement = screen.getByTestId('testSessionSkeleton');
    expect(skeletonElement).toBeInTheDocument();
  });

  it('renders Selection Skeleton', () => {
    render(
      <MemoryRouter>
        <ThemeProvider>
          <SnackbarProvider>
            <SelectionSkeleton />
          </SnackbarProvider>
        </ThemeProvider>
      </MemoryRouter>
    );

    const skeletonElement = screen.getByTestId('selectionSkeleton');
    expect(skeletonElement).toBeInTheDocument();
  });
});
