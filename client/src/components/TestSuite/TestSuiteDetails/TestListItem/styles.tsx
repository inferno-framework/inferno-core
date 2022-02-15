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
    minWidth: '30px',
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
  messageType: {
    fontWeight: 600,
  },
  messageMessage: {
    width: '90%',
    padding: '0 !important',
  },
  badgeIcon: {
    margin: '0 4px',
  },
  testBadge: {
    border: '1px solid #5d89a1',
    color: theme.palette.common.blueLight,
    backgroundColor: theme.palette.common.white,
    fontWeight: 'bold',
  },
  listItem: {
    borderBottom: '1px solid rgba(0,0,0,.12)',
  },
  collapsible: {
    backgroundColor: 'rgba(0,0,0,0.05)',
  },
  descriptionPanel: {
    padding: '16px',
    overflow: 'auto',
    borderBottom: '1px solid rgba(224, 224, 224, 1)',
  },
  resultMessageMarkdown: {
    '& > *': {
      margin: 0,
    },
    marginLeft: '46px',
    marginBottom: '15px',
    color: 'rgba(0,0,0,0.6)',
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
