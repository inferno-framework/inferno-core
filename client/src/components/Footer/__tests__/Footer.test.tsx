import React from 'react';
import { render } from '@testing-library/react';
import Footer from '..';
import ThemeProvider from 'components/ThemeProvider';

test('renders Inferno Footer', () => {
  render(
    <ThemeProvider>
      <Footer version={'dummyVersion'} />
    </ThemeProvider>
  );
});
