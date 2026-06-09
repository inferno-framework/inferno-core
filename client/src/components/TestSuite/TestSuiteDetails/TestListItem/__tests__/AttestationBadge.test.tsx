import React from 'react';
import { render, screen } from '@testing-library/react';
import ThemeProvider from 'components/ThemeProvider';
import { describe, expect, test } from 'vitest';

import AttestationBadge from '../AttestationBadge';

describe('The AttestationBadge component', () => {
  test('it renders the badge with correct label', () => {
    render(
      <ThemeProvider>
        <AttestationBadge />
      </ThemeProvider>,
    );

    const badge = screen.getByText('Attestation');
    expect(badge).toBeDefined();
  });

  test('it renders with a person icon', () => {
    const { container } = render(
      <ThemeProvider>
        <AttestationBadge />
      </ThemeProvider>,
    );

    const icon = container.querySelector('.MuiChip-icon');
    expect(icon).toBeDefined();
  });

  test('it renders the tooltip with the correct text', () => {
    render(
      <ThemeProvider>
        <AttestationBadge />
      </ThemeProvider>,
    );

    const chip = screen.getByText('Attestation').closest('.MuiChip-root');
    expect(chip).toBeDefined();
  });
});
