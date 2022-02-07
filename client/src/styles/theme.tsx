import { createTheme } from '@mui/material';

// https://material-ui.com/customization/palette/#adding-new-colors
declare module '@mui/material/styles/createPalette' {
  interface CommonColors {
    white: string;
    offWhite: string;
    black: string;
    red: string;
    orange: string;
    blue: string;
    blueLight: string;
    blueLighter: string;
    gray: string;
    grayMedium: string;
    grayBlue: string;
    grayLight: string;
    grayLighter: string;
    grayDark: string;
    grayVeryDark: string;
    blueGray: string;
  }
}
const colors = {
  white: '#fff',
  offWhite: '#f1f8ff',
  black: '#222',
  red: '#d95d77',
  orange: '#F88B30',
  blue: '#5d89a1',
  blueLight: '#5d89a1',
  blueLighter: '#9ad2f0',
  gray: '#4a4a4a',
  grayMedium: '#bbbdc0',
  grayBlue: '#cbd5df',
  grayLight: '#9e9e9e',
  grayLighter: '#eaeef2',
  grayDark: '#444',
  grayVeryDark: '#3a3a3a',
  green: '#2fa874',
  blueGray: '#e6ebf2',
};

const paletteBase = {
  primary: {
    main: colors.orange,
  },
  secondary: {
    main: colors.blue,
  },
  common: colors,
};

const lightTheme = createTheme({
  palette: { ...paletteBase },
  typography: {
    h2: {
      fontWeight: 'bold',
      fontFamily: ['Roboto Condensed', 'sans-serif'].join(','),
    },
  },
});

export default lightTheme;
