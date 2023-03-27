// Necessary to override default z-index value of appbar
/* eslint-disable @typescript-eslint/no-explicit-any */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */

import { Theme } from '@mui/material/styles';
import { makeStyles } from 'tss-react/mui';

export default makeStyles()((theme: Theme) => ({
  cancelButton: {
    color: theme.palette.common.blueLight,
    '&:disabled': {
      color: theme.palette.common.gray,
    },
  },
  linearProgress: {
    height: 8,
    backgroundColor: 'rgba(0,0,0,.2)',
    borderRadius: 2,
  },
}));
