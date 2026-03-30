import React from 'react';
import { render, screen } from '@testing-library/react';
import ThemeProvider from 'components/ThemeProvider';
import { describe, expect, test } from 'vitest';

import TestGroupCard from '../TestGroupCard';
import { TestGroup } from '~/models/testSuiteModels';

describe('TestGroupCard', () => {
  test('renders simulation verification badge in header', () => {
    const tg: TestGroup = {
      id: 'card-tg',
      title: 'Card Group',
      inputs: [],
      short_id: 'cg',
      test_groups: [],
      outputs: [],
      tests: [],
      is_simulation_verification: true,
    };

    render(
      <ThemeProvider>
        <TestGroupCard runnable={tg} view="run">
          <div>child</div>
        </TestGroupCard>
      </ThemeProvider>,
    );

    expect(screen.getByText('Simulation Verification')).toBeInTheDocument();
  });
});
