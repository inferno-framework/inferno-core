// Necessary to override default z-index value of appbar
/* eslint-disable @typescript-eslint/no-explicit-any */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */

import { Theme } from '@mui/material/styles';
import makeStyles from '@mui/styles/makeStyles';

export default makeStyles((theme: Theme) => ({
  appbar: {
    width: '100%',
    overflow: 'auto',
    minHeight: '64px', // For responsive screens
    maxHeight: '64px', // For responsive screens
    zIndex: `${theme.zIndex.drawer + 1} !important` as any,
    position: 'sticky',
    '& .MuiTypography-root': {
      display: 'flex',
      justifyContent: 'center',
      flexDirection: 'column',
    },
    '@media print': {
      display: 'none',
    },
  },
  toolbar: {
    display: 'flex',
    justifyContent: 'space-between',
  },
  logo: {
    objectFit: 'contain',
    height: '2.75em',
  },
  titleContainer: {
    display: 'flex',
    alignItems: 'baseline',
    alignSelf: 'center',
    width: 'max-content',
  },
  title: {
    padding: '0 8px',
    width: 'max-content',
  },
  version: {
    fontStyle: 'italic',
  },
}));
