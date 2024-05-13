import { createTheme } from '@mui/material/styles';

// https://material-ui.com/customization/palette/#adding-new-colors
declare module '@mui/material/styles/createPalette' {
  interface CommonColors {
    white: string;
    orangeLight: string;
    orange: string;
    orangeDark: string;
    blueLightest: string;
    blueLight: string;
    blue: string;
    grayLight: string;
    gray: string;
    grayDark: string;
    grayDarkest: string;
  }
}
const colors = {
  white: '#fff',
  orangeLight: '#fbe2cd',
  orange: '#f77a25',
  orangeDark: '#c05702',
  blueLightest: '#f1f8ff',
  blueLight: '#9ad2f0',
  blue: '#316DB1',
  grayLight: '#F0F2F1',
  gray: '#707070',
  grayDark: '#616161',
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
  palette: {
    ...paletteBase,
    contrastThreshold: 4.5,
  },
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
