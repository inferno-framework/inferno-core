import React from 'react';
import { render, screen, fireEvent, within } from '@testing-library/react';
import ThemeProvider from 'components/ThemeProvider';
import { describe, expect, test } from 'vitest';

import TestGroupListItem from '../TestGroupListItem';
import NavigableGroupListItem from '../NavigableGroupListItem';
import { TestGroup } from '~/models/testSuiteModels';

describe('TestGroupListItem simulation badge', () => {
  test('accordion header shows badge for simulation verification groups', () => {
    const tg: TestGroup = {
      id: 'agg-tg',
      title: 'Accordion Group',
      inputs: [],
      short_id: 'agg',
      test_groups: [],
      outputs: [],
      tests: [],
      is_simulation_verification: true,
      expanded: true,
    };

    render(
      <ThemeProvider>
        <TestGroupListItem testGroup={tg} view="run" />
      </ThemeProvider>,
    );

    const summary = screen.getByTestId('agg-tg-summary');
    fireEvent.click(summary);

    expect(screen.getByText('Simulation Verification')).toBeInTheDocument();
  });

  test('navigable (collapsed) group shows badge', () => {
    const tg: TestGroup = {
      id: 'nav-tg',
      title: 'Nav Group',
      inputs: [],
      short_id: 'nav',
      test_groups: [],
      outputs: [],
      tests: [],
      is_simulation_verification: true,
    };

    render(
      <ThemeProvider>
        <NavigableGroupListItem testGroup={tg} />
      </ThemeProvider>,
    );

    expect(screen.getByText('Simulation Verification')).toBeInTheDocument();
  });
});

describe('TestGroupListItem tester-initiated exchange badge', () => {
  test('accordion header shows badge for tester-initiated exchange groups', () => {
    const tg: TestGroup = {
      id: 'agg-tg',
      title: 'Accordion Group',
      inputs: [],
      short_id: 'agg',
      test_groups: [],
      outputs: [],
      tests: [],
      is_tester_initiated_exchange: true,
      expanded: true,
    };

    render(
      <ThemeProvider>
        <TestGroupListItem testGroup={tg} view="run" />
      </ThemeProvider>,
    );

    const summary = screen.getByTestId('agg-tg-summary');
    fireEvent.click(summary);

    expect(screen.getByText('Tester-Initiated Exchange')).toBeInTheDocument();
  });

  test('navigable (collapsed) group shows badge', () => {
    const tg: TestGroup = {
      id: 'nav-tg',
      title: 'Nav Group',
      inputs: [],
      short_id: 'nav',
      test_groups: [],
      outputs: [],
      tests: [],
      is_tester_initiated_exchange: true,
    };

    render(
      <ThemeProvider>
        <NavigableGroupListItem testGroup={tg} />
      </ThemeProvider>,
    );

    expect(screen.getByText('Tester-Initiated Exchange')).toBeInTheDocument();
  });

  test('accordion header shows badge when a nested test is flagged', () => {
    const tg: TestGroup = {
      id: 'agg-inherit-tg',
      title: 'Accordion Group',
      inputs: [],
      short_id: 'agg',
      test_groups: [
        {
          id: 'nested-tg',
          title: 'Nested Group',
          inputs: [],
          short_id: 'nested',
          test_groups: [],
          outputs: [],
          tests: [
            {
              id: 'flagged-test',
              title: 'Flagged Test',
              inputs: [],
              short_id: 'ft',
              outputs: [],
              is_tester_initiated_exchange: true,
            },
          ],
        },
      ],
      outputs: [],
      tests: [],
      expanded: true,
    };

    render(
      <ThemeProvider>
        <TestGroupListItem testGroup={tg} view="run" />
      </ThemeProvider>,
    );

    const summary = screen.getByTestId('agg-inherit-tg-summary');
    expect(within(summary).getByText('Tester-Initiated Exchange')).toBeInTheDocument();
  });

  test('navigable group shows badge when a nested test is flagged', () => {
    const tg: TestGroup = {
      id: 'nav-inherit-tg',
      title: 'Nav Group',
      inputs: [],
      short_id: 'nav',
      test_groups: [],
      outputs: [],
      tests: [
        {
          id: 'flagged-test',
          title: 'Flagged Test',
          inputs: [],
          short_id: 'ft',
          outputs: [],
          is_tester_initiated_exchange: true,
        },
      ],
    };

    render(
      <ThemeProvider>
        <NavigableGroupListItem testGroup={tg} />
      </ThemeProvider>,
    );

    expect(screen.getByText('Tester-Initiated Exchange')).toBeInTheDocument();
  });
});
