import { Theme } from '@mui/material/styles';
import { makeStyles } from 'tss-react/mui';

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
    color: theme.palette.common.grayDarkest,
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
    backgroundColor: theme.palette.common.grayLighter,
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
  nestedDescription: {
    padding: '8px 16px 24px 16px',
    overflow: 'auto',
  },
  nestedDescriptionHeader: {
    fontWeight: 'bolder !important',
    color: theme.palette.common.orangeDarker,
  },
  nestedDescriptionContainer: {
    backgroundColor: theme.palette.common.grayLighter,
    padding: '8px 0',
  },

  // these colors are here for the badges as well as the messages column
  error: {
    color: theme.palette.error.dark,
  },
  warning: {
    color: theme.palette.common.orangeDarker,
  },
  info: {
    color: theme.palette.info.dark,
  },
  request: {
    color: theme.palette.secondary.main,
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
      color: theme.palette.common.orangeDarker,
      border: `1px solid ${theme.palette.common.orangeDarker}`,
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
      color: theme.palette.secondary.main,
      border: `1px solid ${theme.palette.secondary.main}`,
    },
  },
}));
