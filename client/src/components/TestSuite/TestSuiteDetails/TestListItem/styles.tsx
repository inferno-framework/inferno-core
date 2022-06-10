import { Theme } from '@mui/material/styles';

import makeStyles from '@mui/styles/makeStyles';

export default makeStyles((theme: Theme) => ({
  root: {
    backgroundColor: theme.palette.background.paper,
  },
  table: {
    width: 'auto',
    tableLayout: 'auto',
  },
  testIcon: {
    padding: '0 8px 0 0',
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
    color: theme.palette.common.grayLight,
    paddingRight: '4px',
  },
  shortId: {
    display: 'inline',
    fontWeight: 'bold',
    color: theme.palette.common.grayDark,
    alignSelf: 'center',
  },
  tabs: {
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
  badgeIcon: {
    margin: '0 8px',
    padding: '0.25em 0.25em', // offset for hover styling
    '&:hover': {
      background: theme.palette.common.grayLightest,
      borderRadius: '50%',
    },
  },
  testBadge: {
    border: `1px solid ${theme.palette.secondary.main}`,
    color: theme.palette.secondary.main,
    backgroundColor: theme.palette.common.white,
    fontWeight: 'bold',
    // offset for icon padding
    right: 12,
    top: 8,
  },
  accordion: {
    '&:before': {
      display: 'none',
    },
    '&:not(last-child)': {
      borderBottom: `1px solid ${theme.palette.divider}`,
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
    backgroundColor: 'rgba(0,0,0,0.05)',
    padding: 0,
  },
  resultMessageMarkdown: {
    '& > *': {
      margin: 0,
    },
  },
  requestUrl: {
    overflow: 'hidden',
    maxHeight: '1.5em',
    wordBreak: 'break-all',
    display: '-webkit-box',
    WebkitBoxOrient: 'vertical',
    WebkitLineClamp: '1',
  },
  requestUrlContainer: {
    width: '100%',
  },
  messageTypeText: {
    paddingLeft: '3px',
    position: 'relative',
    top: '-8px',
    fontSize: '13px',
  },
  problemBadge: {
    fontWeight: 'bold',
    zIndex: '1',
    '&:focus': {
      outline: 'none',
    },
  },

  // these colors are here for the badges as well as the messages column
  error: {
    color: '#F44336',
  },
  warning: {
    color: '#F88B30',
  },
  info: {
    color: theme.palette.info.dark,
  },

  // common styling for the badge component inside a ProblemBadge
  badgeBase: {
    '& .MuiBadge-badge': {
      backgroundColor: 'white',
      top: '22%',
      right: '14px',
      zIndex: '10',
    },
  },

  // each badge component inside a ProblemBadge has its own color
  // depending on severity
  errorBadge: {
    '& .MuiBadge-badge': {
      color: theme.palette.error.main,
      border: `1px solid ${theme.palette.error.main}`,
    },
  },
  warningBadge: {
    '& .MuiBadge-badge': {
      color: theme.palette.warning.main,
      border: `1px solid ${theme.palette.warning.main}`,
    },
  },
  infoBadge: {
    '& .MuiBadge-badge': {
      color: theme.palette.info.dark,
      border: `1px solid ${theme.palette.info.dark}`,
    },
  },
}));
