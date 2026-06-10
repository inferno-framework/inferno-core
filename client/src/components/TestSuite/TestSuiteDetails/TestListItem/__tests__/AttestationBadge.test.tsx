import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
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
    expect(badge).not.toBeNull();
  });

  test('it renders with a person icon', () => {
    const { container } = render(
      <ThemeProvider>
        <AttestationBadge />
      </ThemeProvider>,
    );

    const icon = container.querySelector('.MuiChip-icon');
    expect(icon).not.toBeNull();
  });

  test('it renders the tooltip with the correct text', async () => {
    render(
      <ThemeProvider>
        <AttestationBadge />
      </ThemeProvider>,
    );

    const chip = screen.getByText('Attestation').closest('.MuiChip-root') as Element;
    fireEvent.mouseOver(chip);

    const tooltip = await screen.findByText('Inferno cannot independently verify this behavior.');
    expect(tooltip).not.toBeNull();
  });
});
