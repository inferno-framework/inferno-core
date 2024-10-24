import { Theme } from '@mui/material/styles';
import { makeStyles } from 'tss-react/mui';

export default makeStyles()((theme: Theme) => ({
  cancelButton: {
    position: 'absolute',
    right: 8,
    top: 8,
  },
  inputField: {
    marginTop: '0 !important',
    '& > label.MuiInputLabel-shrink': {
      fontWeight: 600,
      color: theme.palette.common.grayDarkest,
    },
    '& label.Mui-focused': {
      color: theme.palette.secondary.main,
    },
    '& label.Mui-disabled': {
      color: theme.palette.common.gray,
    },
    '& label.Mui-error': {
      color: theme.palette.error.main,
    },
  },
  inputLabel: {
    color: theme.palette.common.grayDark,
    fontWeight: 600,
  },
  inputDescription: {
    fontSize: '0.95rem',
    color: theme.palette.common.gray,
    '& > p': {
      margin: '0 0 8px 0 !important',
      lineHeight: '1.75rem',
    },
    '& .Mui-disabled': {
      color: theme.palette.common.grayDark,
    },
  },
  lockedIcon: {
    marginLeft: '5px',
    verticalAlign: 'text-bottom',
  },
  textarea: {
    resize: 'vertical',
    maxHeight: '400px',
    overflow: 'auto !important',
  },
  authCard: {
    width: '100%',
    mx: 2,
    borderColor: theme.palette.common.gray,
    '& :focus-within': {
      borderColor: theme.palette.secondary.main,
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
      '& .Mui-disabled': {
        border: 0,
      },
      '& :not(:first-of-type), :first-of-type': {
        borderRadius: theme.shape.borderRadius,
      },
    },
  },
  toggleButton: {
    color: theme.palette.common.grayDark,
    '& :hover, :focus-within': {
      backgroundColor: theme.palette.common.grayLight,
      fontWeight: 'bolder',
    },
    '& .Mui-selected': {
      backgroundColor: 'unset',
      border: `1px solid ${theme.palette.secondary.main} !important`,
      color: theme.palette.secondary.main,
      fontWeight: 'bolder',
    },
  },
}));
