import React, { FC, ReactNode } from 'react';

import { ThemeProvider as MuiThemeProvider, Theme, StyledEngineProvider } from '@mui/material';
import lightTheme from 'styles/theme';

declare module '@mui/styles/defaultTheme' {
  // eslint-disable-next-line @typescript-eslint/no-empty-interface
  interface DefaultTheme extends Theme {}
}

interface ThemeProviderProps {
  children: ReactNode;
}

const ThemeProvider: FC<ThemeProviderProps> = ({ children }) => {
  return (
    <StyledEngineProvider injectFirst>
      <MuiThemeProvider theme={lightTheme}>{children}</MuiThemeProvider>
    </StyledEngineProvider>
  );
};

export default ThemeProvider;
