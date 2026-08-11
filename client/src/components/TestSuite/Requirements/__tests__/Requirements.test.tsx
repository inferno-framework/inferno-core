import React from 'react';
import { renderWithProviders, screen, fireEvent } from '~/test-utils';
import Requirements from '~/components/TestSuite/Requirements/Requirements';
import { requirements, testSuites } from '~/components/App/__mocked_data__/mockData';
import { describe, expect, it, test } from 'vitest';

test('renders Requirements', () => {
  renderWithProviders(
    <Requirements
      requirements={requirements}
      requirementToTests={new Map()}
      testSuiteTitle={testSuites[0].title}
    />,
  );
  expect(screen.getByText('Suite One Specification Requirements')).toBeInTheDocument();
});

describe('filter interactions', () => {
  function renderRequirements() {
    return renderWithProviders(
      <Requirements
        requirements={requirements}
        requirementToTests={new Map()}
        testSuiteTitle={testSuites[0].title}
      />,
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
