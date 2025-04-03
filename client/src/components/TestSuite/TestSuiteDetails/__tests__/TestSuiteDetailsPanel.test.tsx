import React from 'react';
import { MemoryRouter } from 'react-router';
import { render, screen } from '@testing-library/react';
import { SnackbarProvider } from 'notistack';
import ThemeProvider from 'components/ThemeProvider';
import TestSuiteDetailsPanel from '~/components/TestSuite//TestSuiteDetails/TestSuiteDetailsPanel';
import { mockedTestSuite } from '~/components/_common/__mocked_data__/mockData';
import { mockedRunTests } from '~/components/TestSuite/TestRunButton/__mocked_data__/mockData';
import { mockedRequestFunctions } from '~/components/RequestDetailModal/__mocked_data__/mockData';
import { expect, test } from 'vitest';

test('renders TestSuiteDetailsPanel for test suite', () => {
  render(
    <MemoryRouter>
      <ThemeProvider>
        <SnackbarProvider>
          <TestSuiteDetailsPanel
            runnable={mockedTestSuite}
            runTests={mockedRunTests}
            updateRequest={mockedRequestFunctions.updateRequest}
          />
        </SnackbarProvider>
      </ThemeProvider>
    </MemoryRouter>,
  );

  const suiteTitleElement = screen.getByText(mockedTestSuite.title);
  expect(suiteTitleElement).toBeInTheDocument();

  const groupTitles = mockedTestSuite.test_groups?.map((group) => group.title) || [];
  groupTitles.forEach((groupTitle) => {
    const groupTitleElement = screen.getByText(groupTitle);
    expect(groupTitleElement).toBeInTheDocument();
  });
});
