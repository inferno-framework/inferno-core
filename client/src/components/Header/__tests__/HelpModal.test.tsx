import React from 'react';
import { renderWithProviders, screen } from '~/test-utils';
import { expect, test, vi } from 'vitest';
import HelpModal from '../HelpModal';

test('renders HelpModal when visible', () => {
  renderWithProviders(<HelpModal modalVisible={true} hideModal={() => {}} />);
  expect(screen.getByTestId('HelpModal')).toBeVisible();
});

test('does not show HelpModal when not visible', () => {
  renderWithProviders(<HelpModal modalVisible={false} hideModal={() => {}} />);
  expect(screen.queryByTestId('HelpModal')).not.toBeInTheDocument();
});

test('clicking close button calls hideModal', async () => {
  const hideModal = vi.fn();
  const { user } = renderWithProviders(<HelpModal modalVisible={true} hideModal={hideModal} />);

  await user.click(screen.getByTestId('cancel-button'));
  expect(hideModal).toHaveBeenCalledTimes(1);
});

test('keyboard events inside modal do not propagate', async () => {
  const onKeyDown = vi.fn();
  const { user } = renderWithProviders(
    <div onKeyDown={onKeyDown}>
      <HelpModal modalVisible={true} hideModal={() => {}} />
    </div>,
  );

  const modal = screen.getByTestId('HelpModal');
  await user.click(modal);
  await user.keyboard('{Escape}');

  expect(onKeyDown).not.toHaveBeenCalled();
});
