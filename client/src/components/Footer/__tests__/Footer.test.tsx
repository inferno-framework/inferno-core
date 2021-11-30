import React from 'react';
import { render, screen } from '@testing-library/react';
import Footer from '..';
import ThemeProvider from 'components/ThemeProvider';

test('renders Inferno Footer', () => {
  render(
    <ThemeProvider>
      <Footer />
    </ThemeProvider>
  );
  const linkElement = screen.getByText(/Open Source/i);
  expect(linkElement).toBeInTheDocument();
});

test('should navigate elsewhere when link is clicked', () => {
  render(
    <ThemeProvider>
      <Footer githubLink="https://github.com/onc-healthit/inferno" />
    </ThemeProvider>
  );

  expect(screen.getByText(/Open Source/i).closest('a')).toHaveAttribute(
    'href',
    'https://github.com/onc-healthit/inferno'
  );
});
