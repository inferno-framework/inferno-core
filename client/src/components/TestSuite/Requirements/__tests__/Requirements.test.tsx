import React from 'react';
import { BrowserRouter } from 'react-router';
import { render, screen, fireEvent } from '@testing-library/react';
import { SnackbarProvider } from 'notistack';
import ThemeProvider from 'components/ThemeProvider';
import Requirements from '~/components/TestSuite/Requirements/Requirements';
import { requirements, testSuites } from '~/components/App/__mocked_data__/mockData';
import { describe, expect, it, test } from 'vitest';

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

describe('filter interactions', () => {
  function renderRequirements() {
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
  }

  it('specification filter exercises updateFilters and filterRequirements', () => {
    renderRequirements();
    const specCombobox = screen.getByRole('combobox', { name: /specification/i });
    fireEvent.change(specCombobox, { target: { value: 'sample' } });
    fireEvent.click(screen.getByRole('option', { name: 'sample-criteria-proposal' }));
    expect(screen.getByText(/feugiat in ante metus/i)).toBeInTheDocument();
  });

  it('conformance filter with no matching value shows the empty state', () => {
    renderRequirements();
    const conformanceCombobox = screen.getByRole('combobox', { name: /conformance/i });
    fireEvent.change(conformanceCombobox, { target: { value: 'MAY' } });
    fireEvent.click(screen.getByRole('option', { name: 'MAY' }));
    expect(screen.getByText('No requirements found.')).toBeInTheDocument();
  });

  it('Reset Filters button restores all requirements after filtering', () => {
    renderRequirements();
    const conformanceCombobox = screen.getByRole('combobox', { name: /conformance/i });
    fireEvent.change(conformanceCombobox, { target: { value: 'MAY' } });
    fireEvent.click(screen.getByRole('option', { name: 'MAY' }));
    expect(screen.getByText('No requirements found.')).toBeInTheDocument();

    fireEvent.click(screen.getByRole('button', { name: /reset filters/i }));
    expect(screen.queryByText('No requirements found.')).not.toBeInTheDocument();
    expect(screen.getByText(/feugiat in ante metus/i)).toBeInTheDocument();
  });
});
