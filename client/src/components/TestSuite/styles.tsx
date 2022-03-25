import { Theme } from '@mui/material/styles';

import makeStyles from '@mui/styles/makeStyles';

export default makeStyles((theme: Theme) => ({
  root: {
    backgroundColor: theme.palette.background.paper,
  },
  contentContainer: {
    flexGrow: 1,
    margin: '24px 48px',
    '@media print': {
      margin: 0,
    },
  },
  drawer: {
    flexShrink: 0,
    width: '300px',
    '@media print': {
      display: 'none',
    },
  },
  testSessionContainer: {
    display: 'flex',
    flexDirection: 'column',
    height: '100%',
  },
  testSuiteMain: {
    display: 'flex',
    flexGrow: 1,
  },
  spacerToolbar: {
    '@media print': {
      display: 'none',
    },
  },
  drawerPaper: {
    position: 'inherit',
  },
}));
