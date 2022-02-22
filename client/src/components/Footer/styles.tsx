// Necessary to override default z-index value of appbar
/* eslint-disable @typescript-eslint/no-explicit-any */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */

import { Theme } from '@mui/material/styles';
import makeStyles from '@mui/styles/makeStyles';

export default makeStyles((theme: Theme) => ({
  footer: {
    width: '100%',
    zIndex: `${theme.zIndex.drawer + 1} !important` as any,
    backgroundColor: theme.palette.common.offWhite,
    '& .MuiContainer-root': {
      display: 'flex',
      justifyContent: 'center',
    },
  },
  builtUsingContainer: {
    display: 'flex',
    alignItems: 'center',
    flexDirection: 'row',
  },
  builtUsing: {
    padding: '8px',
    fontStyle: 'italic',
  },
  logo: {
    paddingTop: '2px',
    objectFit: 'contain',
    height: '2.5em',
  },
  version: {
    fontStyle: 'italic',
    padding: '8px',
  },
}));
