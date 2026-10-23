import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import ThemeProvider from 'components/ThemeProvider';
import { describe, expect, test } from 'vitest';

import TesterInitiatedExchangeBadge from '../TesterInitiatedExchangeBadge';

describe('The TesterInitiatedExchangeBadge component', () => {
  test('it renders the badge with correct label', () => {
    render(
      <ThemeProvider>
        <TesterInitiatedExchangeBadge />
      </ThemeProvider>,
    );

    const badge = screen.getByText('Tester-Initiated Exchange');
    expect(badge).not.toBeNull();
  });

  test('it renders with a swap icon', () => {
    const { container } = render(
      <ThemeProvider>
        <TesterInitiatedExchangeBadge />
      </ThemeProvider>,
    );

    const icon = container.querySelector('.MuiChip-icon');
    expect(icon).not.toBeNull();
  });

  test('it renders the tooltip with the correct text', async () => {
    render(
      <ThemeProvider>
        <TesterInitiatedExchangeBadge />
      </ThemeProvider>,
    );

    const chip = screen.getByText('Tester-Initiated Exchange').closest('.MuiChip-root') as Element;
    fireEvent.mouseOver(chip);

    const tooltip = await screen.findByText(
      'Requires the system under test to send requests to Inferno.',
    );
    expect(tooltip).not.toBeNull();
  });
});
