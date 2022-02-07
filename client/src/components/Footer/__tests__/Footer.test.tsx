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
});
