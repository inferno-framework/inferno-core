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
  serialInput: {
    height: 'max-content',
    fontFamily: 'monospace',
  },
  dialogActions: {
    display: 'flex',
    justifyContent: 'space-between',
  },
  toggleButtonGroupContainer: {
    display: 'flex',
    border: `1px solid ${theme.palette.divider}`,
    flexWrap: 'wrap',
  },
  toggleButtonGroup: {
    flexGrow: 1,
    '& .MuiToggleButtonGroup-grouped': {
      margin: theme.spacing(0.5),
      border: 0,
      '&.Mui-disabled': {
        border: 0,
      },
      '&:not(:first-of-type), :first-of-type': {
        borderRadius: theme.shape.borderRadius,
      },
    },
  },
  toggleButton: {
    color: theme.palette.common.grayDark,
    '&:focus-within': {
      backgroundColor: theme.palette.common.grayLightest,
    },
    '&.Mui-selected': {
      color: theme.palette.secondary.dark,
      fontWeight: 'bolder',
    },
  },
}));
