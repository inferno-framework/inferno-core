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
    paddingRight: '8px',
  },
  shortId: {
    display: 'inline',
    fontWeight: 'bold',
    color: theme.palette.common.grayDark,
    alignSelf: 'center',
    paddingRight: '8px',
  },
  tabs: {
    minheight: 'auto',
    padding: 0,
  },
  bolderText: {
    fontWeight: 'bolder',
  },
  testCardList: {
    padding: 0,
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
    margin: '0 4px',
  },
  testBadge: {
    border: `1px solid ${theme.palette.secondary.main}`,
    color: theme.palette.secondary.main,
    backgroundColor: theme.palette.common.white,
    fontWeight: 'bold',
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
