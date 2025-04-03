import React from 'react';
import { MemoryRouter } from 'react-router';
import { render, screen } from '@testing-library/react';
import { SnackbarProvider } from 'notistack';
import ThemeProvider from 'components/ThemeProvider';
import TestSuiteReport from '../TestSuiteReport';
import { mockedTestSuite } from '~/components/_common/__mocked_data__/mockData';
import { expect, test } from 'vitest';

test('renders TestSuiteReport', () => {
  render(
    <MemoryRouter>
      <ThemeProvider>
        <SnackbarProvider>
          <TestSuiteReport testSuite={mockedTestSuite} />
        </SnackbarProvider>
      </ThemeProvider>
    </MemoryRouter>,
  );

  const reportTitleElement = screen.getByText(`${mockedTestSuite.title} Report`);
  expect(reportTitleElement).toBeInTheDocument();
});
