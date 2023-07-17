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
      color: 'rgba(0,0,0,0.85)',
    },
    '& label.Mui-focused': {
      color: theme.palette.primary.main,
    },
    '& label.Mui-disabled': {
      color: theme.palette.common.gray,
    },
  },
  inputLabel: {
    color: 'rgba(0,0,0,0.85)',
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
