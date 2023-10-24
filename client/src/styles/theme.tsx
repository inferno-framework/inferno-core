import { createTheme } from '@mui/material/styles';

// https://material-ui.com/customization/palette/#adding-new-colors
declare module '@mui/material/styles/createPalette' {
  interface CommonColors {
    white: string;
    black: string;
    red: string;
    orangeLightest: string;
    orangeLighter: string;
    orange: string;
    orangeDarker: string;
    orangeDarkest: string;
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
    grayDarker: string;
    grayDarkest: string;
  }
}
const colors = {
  white: '#fff',
  black: '#222',
  red: '#d95d77',
  orangeLightest: '#fff8f2',
  orangeLighter: '#ffe4ce',
  orange: '#f88b30',
  orangeDarker: '#c05702',
  orangeDarkest: '#853c00',
  green: '#2fa874',
  blue: '#51788d',
  blueLight: '#9ad2f0',
  blueGray: '#cbd5df',
  blueGrayLighter: '#e6ebf2',
  blueGrayLightest: '#f1f8ff',
  gray: '#707070',
  grayLight: '#bdbdbd',
  grayLighter: '#e0e0e0',
  grayLightest: '#eeeeee',
  grayMedium: '#757575',
  grayDark: '#616161',
  grayDarker: '#424242',
  grayDarkest: '#191919',
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
  zIndex: {
    snackbar: 10,
  },
});

export default lightTheme;
