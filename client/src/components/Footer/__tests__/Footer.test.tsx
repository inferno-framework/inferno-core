import React from 'react';
import { render, screen } from '@testing-library/react';
import Footer from '..';

test('renders Inferno Footer', () => {
  render(<Footer />);
  const linkElement = screen.getByText(/Open Source/i);
  expect(linkElement).toBeInTheDocument();
});

test('should navigate elsewhere when link is clicked', () => {
  render(<Footer githubLink="https://github.com/onc-healthit/inferno" />);

  expect(screen.getByText(/Open Source/i).closest('a')).toHaveAttribute(
    'href',
    'https://github.com/onc-healthit/inferno'
  );
});
