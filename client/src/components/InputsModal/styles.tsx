import { Theme } from '@mui/material/styles';
import { makeStyles } from 'tss-react/mui';

export default makeStyles()((theme: Theme) => ({
  textarea: {
    resize: 'vertical',
    maxHeight: '400px',
    overflow: 'auto !important',
  },
  inputField: {
    '& > label.MuiInputLabel-shrink': {
      fontWeight: 600,
      color: theme.palette.common.grayDarkest,
    },
    '& label.Mui-focused': {
      color: theme.palette.primary.main,
    },
    '& label.Mui-disabled': {
      color: theme.palette.common.gray,
    },
  },
  inputLabel: {
    color: theme.palette.common.grayDarkest,
    fontWeight: 600,
    fontSize: '.75rem',
  },
  lockedIcon: {
    marginLeft: '5px',
    verticalAlign: 'text-bottom',
  },
  oauthCard: {
    width: '100%',
    margin: '8px 0',
    borderColor: theme.palette.common.grayLight,
    '&:focus-within': {
      borderColor: theme.palette.primary.main,
    },
  },
  inputAction: {
    color: theme.palette.primary.dark,
  },
  serialInput: {
    height: 'max-content',
    fontFamily: 'monospace',
  },
  dialogActions: {
    display: 'flex',
  },
  toggleButtonGroup: {
    flexGrow: 1,
  },
  toggleButton: {
    '&.Mui-selected': {
      color: theme.palette.primary.dark,
    },
  },
}));
