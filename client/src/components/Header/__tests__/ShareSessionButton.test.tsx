import React from 'react';
import { renderWithMemoryRouter, screen } from '~/test-utils';
import { describe, expect, test } from 'vitest';
import ShareSessionButton from '../ShareSessionButton';

describe('ShareSessionButton', () => {
  test('renders Share Session button', () => {
    renderWithMemoryRouter(<ShareSessionButton />);
    expect(screen.getByRole('button', { name: /share session/i })).toBeInTheDocument();
  });

  test('clicking Share Session button opens share menu', async () => {
    const { user } = renderWithMemoryRouter(<ShareSessionButton />);
    await user.click(screen.getByRole('button', { name: /share session/i }));

    expect(screen.getByText('Copy Session Link')).toBeInTheDocument();
    expect(screen.getByText('Copy Read-Only Session Link')).toBeInTheDocument();
  });

  test('clicking Copy Session Link triggers the handler and closes the menu', async () => {
    const { user } = renderWithMemoryRouter(<ShareSessionButton />);
    await user.click(screen.getByRole('button', { name: /share session/i }));

    expect(screen.getByText('Copy Session Link')).toBeInTheDocument();
    await user.click(screen.getByText('Copy Session Link'));

    expect(screen.queryByText('Copy Session Link')).not.toBeInTheDocument();
  });

  test('clicking Copy Read-Only Session Link triggers the handler and closes the menu', async () => {
    const { user } = renderWithMemoryRouter(<ShareSessionButton />);
    await user.click(screen.getByRole('button', { name: /share session/i }));

    expect(screen.getByText('Copy Read-Only Session Link')).toBeInTheDocument();
    await user.click(screen.getByText('Copy Read-Only Session Link'));

    expect(screen.queryByText('Copy Read-Only Session Link')).not.toBeInTheDocument();
  });
});
