import { createTheme } from '@mui/material';

// https://material-ui.com/customization/palette/#adding-new-colors
declare module '@mui/material/styles/createPalette' {
  interface CommonColors {
    white: string;
    offWhite: string;
    black: string;
    red: string;
    orange: string;
    orangeDarker: string;
    green: string;
    blue: string;
    blueLight: string;
    blueLighter: string;
    blueGray: string;
    blueGrayLightest: string;
    gray: string;
    grayMedium: string;
    grayBlue: string;
    grayLight: string;
    grayLighter: string;
    grayDark: string;
    grayVeryDark: string;
  }
}
const colors = {
  white: '#fff',
  offWhite: '#fdf6ec',
  black: '#222',
  red: '#d95d77',
  orange: '#F88B30',
  orangeDarker: '#cc7127',
  green: '#2fa874',
  blue: '#5d89a1',
  blueLight: '#5d89a1',
  blueLighter: '#9ad2f0',
  blueGray: '#e6ebf2',
  blueGrayLightest: '#f1f8ff',
  gray: '#4a4a4a',
  grayMedium: '#bbbdc0',
  grayBlue: '#cbd5df',
  grayLight: '#9e9e9e',
  grayLighter: '#eaeef2',
  grayDark: '#444',
  grayVeryDark: '#3a3a3a',
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
