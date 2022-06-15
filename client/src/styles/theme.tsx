import { createTheme } from '@mui/material/styles';

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
  orangeDarker: '#C05702',
  orangeLightest: '#fdf6ec',
  green: '#2fa874',
  blue: '#51788D',
  blueLight: '#9ad2f0',
  blueGray: '#e6ebf2',
  blueGrayLightest: '#f1f8ff',
  gray: '#4a4a4a',
  grayMedium: '#bbbdc0',
  grayBlue: '#cbd5df',
  grayLight: 'rgba(0, 0, 0, 0.6)',
  grayLighter: '#eaeef2',
  grayLightest: '#f2f2f2',
  grayDark: '#595959',
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
