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
    overflow: 'auto',
    '@media print': {
      margin: 0,
      position: 'absolute',
      left: 0,
      right: 0,
      top: '51px', // height of footer
    },
  },
  drawer: {
    display: 'flex',
    flexGrow: 1,
    '@media print': {
      display: 'none',
    },
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
