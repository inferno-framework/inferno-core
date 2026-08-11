import React from 'react';
import { renderWithProviders, screen } from '~/test-utils';
import { describe, expect, test, vi } from 'vitest';
import ErrorOutlineIcon from '@mui/icons-material/ErrorOutline';
import ProblemBadge from '../ProblemBadge';

const defaultProps = {
  Icon: ErrorOutlineIcon,
  counts: 3,
  color: 'red',
  badgeStyle: 'badge',
  description: 'Errors',
  view: 'run',
};

describe('ProblemBadge', () => {
  test('renders badge with count', () => {
    renderWithProviders(<ProblemBadge {...defaultProps} />);
    expect(screen.getByText('3')).toBeInTheDocument();
  });

  test('clicking badge opens panel', async () => {
    const setPanelIndex = vi.fn();
    const setOpen = vi.fn();
    const { user } = renderWithProviders(
      <ProblemBadge
        {...defaultProps}
        panelIndex={1}
        setPanelIndex={setPanelIndex}
        setOpen={setOpen}
      />,
    );

    const badge = screen.getByText('3').closest('span')!;
    await user.click(badge);

    expect(setPanelIndex).toHaveBeenCalledWith(1);
    expect(setOpen).toHaveBeenCalledWith(true);
  });

  test('does not open panel when view is report', async () => {
    const setOpen = vi.fn();
    const { user } = renderWithProviders(
      <ProblemBadge {...defaultProps} view="report" setOpen={setOpen} />,
    );

    const badge = screen.getByText('3').closest('span')!;
    await user.click(badge);

    expect(setOpen).not.toHaveBeenCalled();
  });

  test('pressing Enter on the icon opens panel', async () => {
    const setOpen = vi.fn();
    const { user } = renderWithProviders(
      <ProblemBadge {...defaultProps} panelIndex={0} setPanelIndex={vi.fn()} setOpen={setOpen} />,
    );

    const icon = screen.getByLabelText('View Errors');
    icon.focus();
    await user.keyboard('{Enter}');

    expect(setOpen).toHaveBeenCalledWith(true);
  });
});
