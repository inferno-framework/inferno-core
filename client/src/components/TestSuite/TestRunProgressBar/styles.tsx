// Necessary to override default z-index value of appbar

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
    backgroundColor: theme.palette.common.grayDark,
    borderRadius: 2,
  },
}));
