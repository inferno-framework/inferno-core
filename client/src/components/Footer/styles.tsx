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
      position: 'absolute',
      top: 0,
      bottom: 'unset',
    },
  },
  builtUsingContainer: {
    display: 'flex',
    alignItems: 'center',
    flexDirection: 'row',
  },
  logo: {
    objectFit: 'contain',
    height: '2.5em',
  },
  footerText: {
    fontStyle: 'italic',
    padding: '11px 12px 8px 8px',
  },
}));
