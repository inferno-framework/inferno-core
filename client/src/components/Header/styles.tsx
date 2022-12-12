// Necessary to override default z-index value of appbar
/* eslint-disable @typescript-eslint/no-explicit-any */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */

import { Theme } from '@mui/material/styles';
import lightTheme from '~/styles/theme';
import makeStyles from '@mui/styles/makeStyles';

export default makeStyles((theme: Theme) => ({
  appbar: {
    zIndex: `${theme.zIndex.drawer + 1} !important` as any,
    position: 'sticky',
    '@media print': {
      display: 'none',
    },
  },
  toolbar: {
    display: 'flex',
    height: '100%',
    maxWidth: '100vw',
    overflow: 'hidden',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  logo: {
    objectFit: 'contain',
    height: '2.75em',
    paddingRight: '8px',
  },
  title: {
    padding: '0 8px',
    whiteSpace: 'nowrap',
    fontWeight: 600,
  },
  version: {
    fontStyle: 'italic',
  },
  homeLink: {
    color: lightTheme.palette.common.orangeDarker,
    textDecoration: 'none',
  },
}));
