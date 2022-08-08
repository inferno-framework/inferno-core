import { createTheme } from '@mui/material/styles';

// https://material-ui.com/customization/palette/#adding-new-colors
declare module '@mui/material/styles/createPalette' {
  interface CommonColors {
    white: string;
    black: string;
    red: string;
    orange: string;
    orangeLightest: string;
    orangeDarker: string;
    green: string;
    blue: string;
    blueLight: string;
    blueGray: string;
    blueGrayLighter: string;
    blueGrayLightest: string;
    gray: string;
    grayLight: string;
    grayLighter: string;
    grayLightest: string;
    grayMedium: string;
    grayDark: string;
    grayDarkest: string;
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
  blueGray: '#cbd5df',
  blueGrayLighter: '#e6ebf2',
  blueGrayLightest: '#f1f8ff',
  gray: 'rgba(0, 0, 0, 0.6)',
  grayLight: '#cfd8dc',
  grayLighter: '#eaeef2',
  grayLightest: '#f2f2f2',
  grayMedium: '#bbbdc0',
  grayDark: '#595959',
  grayDarkest: '#3a3a3a',
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
