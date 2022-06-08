// Necessary to override default z-index value of appbar
/* eslint-disable @typescript-eslint/no-explicit-any */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */

import { Theme } from '@mui/material/styles';
import makeStyles from '@mui/styles/makeStyles';

export default makeStyles((theme: Theme) => ({
  footer: {
    width: '100%',
    zIndex: `${theme.zIndex.drawer + 1} !important` as any,
    backgroundColor: theme.palette.common.orangeLightest,
    position: 'sticky',
    bottom: 0,
    '@media print': {
      display: 'none',
    },
  },
  logo: {
    objectFit: 'contain',
    height: '3em',
    padding: '4px 8px 4px 0',
  },
  logoText: {
    fontStyle: 'italic',
    textTransform: 'uppercase',
  },
  linkText: {
    fontWeight: 'bolder',
    fontSize: '1.1rem',
    margin: '0 16px',
    color: theme.palette.common.grayDark,
  },
}));
