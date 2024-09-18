import React from 'react';
import { BrowserRouter } from 'react-router-dom';
import { render, screen } from '@testing-library/react';
import { SnackbarProvider } from 'notistack';
import ThemeProvider from 'components/ThemeProvider';
import { testSuites } from '~/components/App/__mocked_data__/mockData';
import ConfigMessagesDetailsPanel from '../ConfigMessagesDetailsPanel';
import { expect, test } from 'vitest';

test('renders ConfigMessagesDetailsPanel', () => {
  render(
    <BrowserRouter>
      <ThemeProvider>
        <SnackbarProvider>
          <ConfigMessagesDetailsPanel testSuite={testSuites[0]} />
        </SnackbarProvider>
      </ThemeProvider>
    </BrowserRouter>,
  );

  const tabsList = screen.getAllByRole('tab');
  expect(tabsList.length).toEqual(3);

  expect(screen.getByLabelText('Errors')).toBeInTheDocument();
  expect(screen.getByLabelText('Warnings')).toBeInTheDocument();
  expect(screen.getByLabelText('Info')).toBeInTheDocument();
});
