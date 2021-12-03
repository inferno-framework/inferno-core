import { Theme } from '@mui/material/styles';

import makeStyles from '@mui/styles/makeStyles';

export default makeStyles((theme: Theme) => ({
  root: {
    backgroundColor: theme.palette.background.paper,
  },
  testIcon: {
    minWidth: '30px',
    display: 'inline-flex',
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
  },
  testBadge: {
    margin: '0 4px',
  },
  listItem: {
    borderBottom: '1px solid rgba(0,0,0,.12)',
  },
  collapsible: {
    backgroundColor: 'rgba(0,0,0,0.05)',
  },
  descriptionPanel: {
    padding: '15px',
    overflow: 'auto',
  },
  resultMessageMarkdown: {
    '& > *': {
      margin: 0,
    },
    marginLeft: '46px',
    marginBottom: '15px',
    color: 'rgba(0,0,0,0.6)',
  },
  requestRowItem: {
    display: 'flex',
    alignItems: 'center',
  },
  requestRow: {
    display: 'flex',
    textAlign: 'center',
    height: '45px',
    '& > *': {
      display: 'flex',
      alignItems: 'center',
      margin: '10px',
    },
  },
  requestUrl: {
    whiteSpace: 'nowrap',
    overflow: 'hidden',
    textOverflow: 'ellipsis',
    flexGrow: 1,
    '& > *': {
      whiteSpace: 'nowrap',
      overflow: 'hidden',
      textOverflow: 'ellipsis',
    },
  },
}));
