import React, { FC, ReactNode } from 'react';

import { ThemeProvider as MuiThemeProvider, StyledEngineProvider } from '@mui/material/styles';
import lightTheme from 'styles/theme';

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
