import { createTheme } from '@mui/material';

// https://material-ui.com/customization/palette/#adding-new-colors
declare module '@mui/material/styles/createPalette' {
  interface CommonColors {
    white: string;
    black: string;
    red: string;
    orange: string;
    orangeDarker: string;
    orangeLightest: string;
    green: string;
    blue: string;
    blueLight: string;
    blueGray: string;
    blueGrayLightest: string;
    gray: string;
    grayMedium: string;
    grayBlue: string;
    grayLight: string;
    grayLighter: string;
    grayLightest: string;
    grayDark: string;
    grayVeryDark: string;
  }
}
const colors = {
  white: '#fff',
  black: '#222',
  red: '#d95d77',
  orange: '#F88B30',
  orangeDarker: '#cc7127',
  orangeLightest: '#fdf6ec',
  green: '#2fa874',
  blue: '#5d89a1',
  blueLight: '#9ad2f0',
  blueGray: '#e6ebf2',
  blueGrayLightest: '#f1f8ff',
  gray: '#4a4a4a',
  grayMedium: '#bbbdc0',
  grayBlue: '#cbd5df',
  grayLight: '#9e9e9e',
  grayLighter: '#eaeef2',
  grayLightest: '#f2f2f2',
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
