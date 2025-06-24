import { Theme } from '@mui/material/styles';
import { makeStyles } from 'tss-react/mui';
import { darken } from '@mui/material/styles';

export default makeStyles()((theme: Theme) => ({
  root: {
    backgroundColor: theme.palette.background.paper,
  },
  table: {
    width: 'auto',
    tableLayout: 'auto',
  },
  testIcon: {
    display: 'inline-flex',
  },
  labelText: {
    display: 'inline',
  },
  optionalLabel: {
    display: 'inline',
    fontStyle: 'italic',
    fontSize: '0.9rem',
    lineHeight: '1.5rem',
    alignSelf: 'center',
    color: theme.palette.common.gray,
    paddingRight: '4px',
  },
  shortId: {
    display: 'inline',
    fontWeight: 'bold',
    color: theme.palette.common.grayDark,
    alignSelf: 'center',
  },
  testText: {
    padding: '0 8px',
    wordBreak: 'break-word',
    minWidth: '100px',
  },
  tabs: {
    backgroundColor: theme.palette.common.white,
    minHeight: 'auto',
    padding: 0,
  },
  bolderText: {
    fontWeight: 'bolder',
  },
  messageMessage: {
    width: '82%',
    padding: '0 16px 0 0 !important',
  },
  inputOutputsValue: {
    width: '90%',
    padding: '0 16px !important',
  },
  noPrintSpacing: {
    '@media print': {
      marginTop: 0,
      marginBottom: 0,
      paddingTop: 0,
      paddingBottom: 0,
      minHeight: 'unset',
    },
  },
  wordWrap: {
    overflowWrap: 'anywhere',
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
      overflow: 'auto',
    },
  },
  accordionDetailContainer: {
    backgroundColor: darken(theme.palette.common.grayLight, 0.1),
    padding: '16px',
    '@media print': {
      padding: '0 16px',
    },
  },
  resultMessageMarkdown: {
    '& > *': {
      margin: 0,
    },
  },
  requestUrlContainer: {
    width: '100%',
  },
  badgeIcon: {
    margin: '0 8px',
    padding: '0.25em 0.25em', // offset for hover styling
    '&:hover': {
      background: theme.palette.common.grayLight,
      borderRadius: '50%',
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

  // common styling for the badge component inside a ProblemBadge
  badgeBase: {
    '& .MuiBadge-badge': {
      backgroundColor: theme.palette.common.white,
      fontWeight: 'bold',
      // offset for icon padding
      top: '0.65rem',
      right: '14px',
    },
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
      color: theme.palette.info.dark,
      border: `1px solid ${theme.palette.info.dark}`,
    },
  },
}));
