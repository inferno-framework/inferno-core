import { Theme } from '@mui/material/styles';

import makeStyles from '@mui/styles/makeStyles';

export default makeStyles((theme: Theme) => ({
  root: {
    backgroundColor: theme.palette.background.paper,
  },
  contentContainer: {
    flexGrow: 1,
    padding: '24px 48px',
    overflowX: 'hidden',
    overflow: 'scroll',
    '@media print': {
      margin: 0,
    },
  },
  testSessionContainer: {
    flexGrow: '1',
    height: '100%',
    display: 'flex',
    flexDirection: 'column',
  },
  testSuiteMain: {
    display: 'flex',
    flexGrow: 1,
    overflow: 'hidden',
    '@media print': {
      maxHeight: 'unset',
    },
  },
  drawerPaper: {
    flexShrink: 0,
    width: '300px',
    position: 'static',
  },
  hidePrint: {
    '@media print': {
      display: 'none',
    },
  },
}));
