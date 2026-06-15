import React from 'react';
import { renderWithProviders, screen } from '~/test-utils';
import { describe, expect, test, vi } from 'vitest';
import TestRunDetail from '../TestRunDetail';
import { mockedTest } from '~/components/_common/__mocked_data__/mockData';

const tabs = [
  { label: 'Messages', value: [] },
  { label: 'Requests', value: [] },
  { label: 'Inputs', value: [] },
  { label: 'Outputs', value: [] },
  { label: 'About', value: 'test description' },
];

describe('TestRunDetail', () => {
  test('renders test run detail card', () => {
    renderWithProviders(
      <TestRunDetail
        test={mockedTest}
        currentTabIndex={0}
        setTabIndex={vi.fn()}
        tabs={tabs}
      />,
    );
    expect(screen.getByTestId('test-run-detail')).toBeInTheDocument();
  });

  test('clicking a tab calls setTabIndex with new index', async () => {
    const setTabIndex = vi.fn();
    const { user } = renderWithProviders(
      <TestRunDetail
        test={mockedTest}
        currentTabIndex={0}
        setTabIndex={setTabIndex}
        tabs={tabs}
      />,
    );

    const aboutTab = screen.getByRole('tab', { name: /About/i });
    await user.click(aboutTab);

    expect(setTabIndex).toHaveBeenCalledWith(4);
  });

  test('shows RequirementsModalButton when test has verifies_requirements', () => {
    const testWithRequirements = {
      ...mockedTest,
      verifies_requirements: ['req-1'],
    };

    renderWithProviders(
      <TestRunDetail
        test={testWithRequirements}
        currentTabIndex={4}
        setTabIndex={vi.fn()}
        tabs={tabs}
      />,
    );

    expect(screen.getByText('View Specification Requirements')).toBeInTheDocument();
  });

  test('does not show RequirementsModalButton when test has no requirements', () => {
    renderWithProviders(
      <TestRunDetail
        test={mockedTest}
        currentTabIndex={4}
        setTabIndex={vi.fn()}
        tabs={tabs}
      />,
    );

    expect(screen.queryByText('View Specification Requirements')).not.toBeInTheDocument();
  });
});
