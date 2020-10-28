import React, { FC, ReactNode } from 'react';

import { ThemeProvider as MuiThemeProvider } from '@material-ui/core';
import lightTheme from 'styles/theme';

interface ThemeProviderProps {
  children: ReactNode;
}

const ThemeProvider: FC<ThemeProviderProps> = ({ children }) => {
  return <MuiThemeProvider theme={lightTheme}>{children}</MuiThemeProvider>;
};

export default ThemeProvider;
