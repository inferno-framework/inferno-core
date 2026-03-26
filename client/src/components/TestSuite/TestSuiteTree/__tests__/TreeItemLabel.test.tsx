import React from 'react';
import { render, screen } from '@testing-library/react';
import ThemeProvider from 'components/ThemeProvider';
import { describe, expect, test } from 'vitest';

import TreeItemLabel from '../TreeItemLabel';
import { TestGroup } from '~/models/testSuiteModels';

describe('TreeItemLabel', () => {
  test('shows simulation verification badge for groups', () => {
    const tg: TestGroup = {
      id: 'tg-1',
      title: 'Nested Group',
      inputs: [],
      short_id: 'ng',
      test_groups: [],
      outputs: [],
      tests: [],
      is_simulation_verification: true,
    };

    render(
      <ThemeProvider>
        <TreeItemLabel runnable={tg} />
      </ThemeProvider>,
    );

    expect(screen.getByText('Simulation Verification')).toBeInTheDocument();
  });
});
