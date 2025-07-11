import React from 'react';
import { BrowserRouter } from 'react-router';
import { render, screen } from '@testing-library/react';
import { SnackbarProvider } from 'notistack';
import ThemeProvider from 'components/ThemeProvider';
import Requirements from '~/components/TestSuite/Requirements/Requirements';
import { requirements, testSuites } from '~/components/App/__mocked_data__/mockData';
import { expect, test } from 'vitest';

test('renders Requirements', () => {
  render(
    <BrowserRouter>
      <ThemeProvider>
        <SnackbarProvider>
          <Requirements
            requirements={requirements}
            requirementToTests={new Map()}
            testSuiteTitle={testSuites[0].title}
          />
        </SnackbarProvider>
      </ThemeProvider>
    </BrowserRouter>,
  );

  expect(screen.getByText('Suite One Specification Requirements')).toBeInTheDocument();
});
