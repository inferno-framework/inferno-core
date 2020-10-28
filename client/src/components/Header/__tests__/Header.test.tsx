import React from 'react';
import { render, screen } from '@testing-library/react';
import Header from '../Header';

test('renders Inferno Header', () => {
  render(<Header chipLabel="Community" />);
  const linkElement = screen.getByText(/Community/i);
  expect(linkElement).toBeInTheDocument();
});
