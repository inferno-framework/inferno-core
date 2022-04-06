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
    '& .MuiContainer-root': {
      display: 'flex',
      justifyContent: 'center',
    },
    position: 'sticky',
    bottom: 0,
    '@media print': {
      position: 'static',
    },
  },
  builtUsingContainer: {
    display: 'flex',
    alignItems: 'center',
    flexDirection: 'row',
  },
  logo: {
    paddingTop: '2px',
    objectFit: 'contain',
    height: '2.5em',
  },
  footerText: {
    fontStyle: 'italic',
    padding: '13px 12px 8px 8px',
  },
}));
