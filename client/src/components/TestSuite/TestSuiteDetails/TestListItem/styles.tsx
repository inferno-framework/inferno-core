import { makeStyles, Theme } from '@material-ui/core/styles';

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
    marginRight: '10px',
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
    marginLeft: '45px',
    marginBottom: '5px',
  },
}));
