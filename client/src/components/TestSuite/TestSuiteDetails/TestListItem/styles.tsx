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
    minheight: 'auto',
    padding: 0,
  },
  bolderText: {
    fontWeight: 'bolder',
  },
  messageMessage: {
    width: '90%',
    padding: '0 !important',
  },
  inputOutputsValue: {
    width: '90%',
    padding: '0 !important',
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
}));
