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
      position: 'absolute',
      left: 0,
      right: 0,
      top: '51px', // height of footer
    },
  },
  drawer: {
    '@media print': {
      display: 'none',
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
  },
  spacerToolbar: {
    '@media print': {
      display: 'none',
    },
  },
  drawerPaper: {
    flexShrink: 0,
    width: '300px',
    position: 'static',
  },
}));
