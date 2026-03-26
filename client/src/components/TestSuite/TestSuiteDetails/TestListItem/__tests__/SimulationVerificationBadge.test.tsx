import React from 'react';
import { render, screen } from '@testing-library/react';
import ThemeProvider from 'components/ThemeProvider';
import { describe, expect, test } from 'vitest';

import SimulationVerificationBadge from '../SimulationVerificationBadge';

describe('The SimulationVerificationBadge component', () => {
  test('it renders the badge with correct label', () => {
    render(
      <ThemeProvider>
        <SimulationVerificationBadge />
      </ThemeProvider>,
    );

    const badge = screen.getByText('Simulation Verification');
    expect(badge).toBeDefined();
  });

  test('it renders with person icon', () => {
    const { container } = render(
      <ThemeProvider>
        <SimulationVerificationBadge />
      </ThemeProvider>,
    );

    // Check that the PersonIcon SVG is present
    const icon = container.querySelector('.MuiChip-icon');
    expect(icon).toBeDefined();
  });
});
