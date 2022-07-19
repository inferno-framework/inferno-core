import React from 'react';
import { render, screen } from '@testing-library/react';
import Footer from '..';
import ThemeProvider from 'components/ThemeProvider';

test('renders Inferno Footer', () => {
  render(
    <ThemeProvider>
      <Footer version={'dummyVersion'} />
    </ThemeProvider>
  );
});

test('has no links if not provided any', () => {
  render(
    <ThemeProvider>
      <Footer version={'dummyVersion'} />
    </ThemeProvider>
  );

  // testing a negative is nearly meaningless
  const link = screen.queryByRole('link', { name: /Open Source/ });
  expect(link).not.toBeInTheDocument();
});

test('can be given a list of links to display', () => {
  const links = [
    { label: 'One', url: 'http://one.com' },
    { label: 'Two', url: 'http://two.com' },
  ];

  render(
    <ThemeProvider>
      <Footer version={'dummyVersion'} linkList={links} />
    </ThemeProvider>
  );

  expect(screen.getByRole('link', { name: /One/ })).toHaveAttribute('href', 'http://one.com');
  expect(screen.getByRole('link', { name: /Two/ })).toHaveAttribute('href', 'http://two.com');
});
