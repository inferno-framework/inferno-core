import { Theme } from '@mui/material/styles';
import { makeStyles } from 'tss-react/mui';
import { darken } from '@mui/material/styles';

export default makeStyles()((theme: Theme) => ({
  root: {
    backgroundColor: theme.palette.background.paper,
  },
  labelText: {
    display: 'inline',
  },
  shortId: {
    display: 'inline',
    fontWeight: 'bold',
    alignSelf: 'center',
    color: theme.palette.common.grayDark,
  },
  currentItem: {
    fontWeight: 600,
  },
  accordion: {
    '&:before': {
      display: 'none',
    },
    '&:not(last-child)': {
      borderBottom: `1px solid ${theme.palette.divider}`,
    },
    '@media print': {
      borderTop: `1px solid ${theme.palette.divider}`,
      borderBottom: 'none !important',
    },
  },
  accordionSummary: {
    userSelect: 'auto',
    '@media print': {
      minHeight: 'unset',
    },
    '& .MuiAccordionSummary-content': {
      margin: 0,
    },
  },
  accordionDetailContainer: {
    backgroundColor: theme.palette.common.grayLight,
    '@media print': {
      padding: '0 0 0 16px',
    },
  },
  accordionDetail: {
    backgroundColor: theme.palette.common.white,
    padding: 0,
    margin: '8px 0 0 0',
    borderRadius: '4px',
    '@media print': {
      margin: 0,
    },
  },
  description: {
    padding: '8px 16px 24px 16px',
    overflow: 'auto',
  },
  descriptionHeader: {
    fontWeight: 'bolder !important',
    color: theme.palette.common.orangeDark,
  },
  descriptionContainer: {
    backgroundColor: theme.palette.common.grayLight,
  },
  descriptionDetailContainer: {
    backgroundColor: darken(theme.palette.common.grayLight, 0.1),
    '@media print': {
      padding: '0 0 0 16px',
    },
  },

  // these colors are here for the badges as well as the messages column
  error: {
    color: theme.palette.error.dark,
  },
  warning: {
    color: theme.palette.primary.dark,
  },
  info: {
    color: theme.palette.info.dark,
  },
  request: {
    color: theme.palette.info.main,
  },

  // each badge component inside a ProblemBadge has its own color
  // depending on severity
  errorBadge: {
    '& .MuiBadge-badge': {
      color: theme.palette.error.dark,
      border: `1px solid ${theme.palette.error.dark}`,
    },
  },
  warningBadge: {
    '& .MuiBadge-badge': {
      color: theme.palette.primary.dark,
      border: `1px solid ${theme.palette.primary.dark}`,
    },
  },
  infoBadge: {
    '& .MuiBadge-badge': {
      color: theme.palette.info.dark,
      border: `1px solid ${theme.palette.info.dark}`,
    },
  },
  requestBadge: {
    '& .MuiBadge-badge': {
      color: theme.palette.secondary.dark,
      border: `1px solid ${theme.palette.info.dark}`,
    },
  },
}));
