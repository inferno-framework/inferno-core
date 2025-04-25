import React from 'react';
import { BrowserRouter } from 'react-router-dom';
import { render, screen } from '@testing-library/react';
import { SnackbarProvider } from 'notistack';
import ThemeProvider from 'components/ThemeProvider';
import Requirements from '~/components/TestSuite/Requirements/Requirements';
import { testSuites } from '~/components/App/__mocked_data__/mockData';
import { expect, test } from 'vitest';

test('renders Requirements', () => {
  render(
    <BrowserRouter>
      <ThemeProvider>
        <SnackbarProvider>
          <Requirements testSuite={testSuites[0]} />
        </SnackbarProvider>
      </ThemeProvider>
    </BrowserRouter>,
  );

  expect(screen.getByLabelText('Requirements')).toBeInTheDocument();
});
