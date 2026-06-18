import React from 'react';
import { renderWithProviders, screen } from '~/test-utils';
import { expect, test, vi } from 'vitest';
import CollapseButton from '../CollapseButton';

test('renders collapse button when not collapsed', () => {
  renderWithProviders(<CollapseButton collapsed={false} setCollapsed={() => {}} />);
  expect(screen.getByRole('button', { name: /collapse button/i })).toBeInTheDocument();
});

test('renders expand button when collapsed', () => {
  renderWithProviders(<CollapseButton collapsed={true} setCollapsed={() => {}} />);
  expect(screen.getByRole('button', { name: /expand button/i })).toBeInTheDocument();
});

test('clicking the button toggles collapsed state', async () => {
  const setCollapsed = vi.fn();
  const { user } = renderWithProviders(
    <CollapseButton collapsed={false} setCollapsed={setCollapsed} />,
  );

  await user.click(screen.getByRole('button', { name: /collapse button/i }));
  expect(setCollapsed).toHaveBeenCalledWith(true);
});
