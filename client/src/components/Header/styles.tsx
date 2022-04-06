// Necessary to override default z-index value of appbar
/* eslint-disable @typescript-eslint/no-explicit-any */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */

import { Theme } from '@mui/material/styles';
import makeStyles from '@mui/styles/makeStyles';

export default makeStyles((theme: Theme) => ({
  appbar: {
    zIndex: `${theme.zIndex.drawer + 1} !important` as any,
    position: 'inherit',
    flexDirection: 'row',
    '& .MuiTypography-root': {
      display: 'flex',
      justifyContent: 'center',
      flexDirection: 'column',
    },
  },
  toolbar: {
    display: 'flex',
    justifyContent: 'space-between',
    width: '100%',
    '@media print': {
      display: 'none',
    },
  },
  logo: {
    objectFit: 'contain',
    height: '3em',
  },
  titleContainer: {
    display: 'flex',
    alignItems: 'baseline',
    alignSelf: 'center',
  },
  title: {
    padding: '0 8px',
  },
  version: {
    fontStyle: 'italic',
  },
}));
