import { Theme } from '@mui/material/styles';

import makeStyles from '@mui/styles/makeStyles';

export default makeStyles((theme: Theme) => ({
  textarea: {
    resize: 'vertical',
    maxHeight: '400px',
    overflow: 'auto !important',
  },
  inputField: {
    '& > label.MuiInputLabel-shrink': {
      fontWeight: 600,
      color: 'rgba(0,0,0,0.85)',
    },
    '& label.Mui-focused': {
      color: theme.palette.primary.main,
    },
    '& label.Mui-disabled': {
      color: theme.palette.common.grayLight,
    },
  },
  inputLabel: {
    fontWeight: 600,
    color: 'rgba(0,0,0,0.85)',
    fontSize: '.75rem',
  },
  lockedIcon: {
    marginLeft: '5px',
    verticalAlign: 'text-bottom',
  },
  oauthCard: {
    width: '100%',
    margin: '8px 0',
    borderColor: 'rgba(0,0,0,0.3)',
    '&:focus-within': {
      borderColor: theme.palette.primary.main,
    },
  },
  inputAction: {
    color: theme.palette.primary.dark,
  },
  serialInput: {
    height: 'max-content',
  },
  dialogActions: {
    display: 'flex',
  },
  toggleButtonGroup: {
    marginRight: 'auto',
  },
  toggleButton: {
    '&&': {
      color: theme.palette.primary.dark,
      height: '36px',
      '&:hover': {
        backgroundColor: '#fdf6ec',
        borderLeft: '1px solid #cecece',
      },
      '&:disabled': {
        backgroundColor: '#ebebeb',
        color: theme.palette.common.gray,
      },
    },
  },
}));
