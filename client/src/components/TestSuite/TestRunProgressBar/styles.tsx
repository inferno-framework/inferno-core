// Necessary to override default z-index value of appbar
/* eslint-disable @typescript-eslint/no-explicit-any */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */

import { Theme } from '@mui/material/styles';
import makeStyles from '@mui/styles/makeStyles';

export default makeStyles((theme: Theme) => ({
  linearProgress: {
    height: 8,
    backgroundColor: 'rgba(0,0,0,0)',
    borderRadius: 4,
  },
  snackbar: {
    zIndex: `${theme.zIndex.drawer + 1} !important` as any,
  },
}));
