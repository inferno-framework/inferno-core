import { makeStyles, Theme } from '@material-ui/core/styles';

export default makeStyles((theme: Theme) => ({
  root: {
    backgroundColor: theme.palette.background.paper,
  },
  cardTitleText: {
    flexGrow: 1,
    paddingLeft: '10px',
  },
  clickableText: {
    '&:hover': {
      textDecoration: 'underline',
      textDecorationStyle: 'wavy',
      cursor: 'pointer',
      color: theme.palette.primary,
    },
  },
  testSuiteDetailsPanel: {
    flexGrow: 3,
    height: 'fit-content',
  },
  testSuiteTitle: {
    display: 'flex',
    alignItems: 'center',
    width: '750px',
  },
  testSuiteTitleRunButton: {
    marginLeft: '10px',
  },
  runButton: {
    marginRight: '5px',
  },
  card: {
    margin: '10px 0',
    width: '750px',
  },
  testIcon: {
    minWidth: '30px',
    display: 'inline-flex',
  },
  testCardButton: {
    width: '100%',
    textAlign: 'left',
    padding: '5px 10px 10px 10px',
    boxSizing: 'border-box',
    display: 'block',
  },
  testCardTitle: {
    width: '100%',
    display: 'flex',
    alignItems: 'center',
    paddingTop: '2px',
  },
  groupCardTitle: {
    display: 'flex',
    alignItems: 'center',
    paddingTop: '2px',
    paddingLeft: '10px',
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
  panelTitleText: {
    flexGrow: 1,
  },
  testListItemAlternateRow: {
    backgroundColor: theme.palette.common.blueGray,
  },
  testBadge: {
    marginRight: '10px',
  },
}));
