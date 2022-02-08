import { Theme } from '@mui/material/styles';

import makeStyles from '@mui/styles/makeStyles';

export default makeStyles((theme: Theme) => ({
  root: {
    backgroundColor: theme.palette.background.paper,
  },
  contentContainer: {
    flexGrow: 1,
    margin: '24px 48px',
  },
  drawer: {
    flexShrink: 0,
    width: '300px',
  },
  testSuiteMain: {
    display: 'flex',
    flexGrow: 1,
  },
  testSuitePanel: {
    flexBasis: '300px',
    margin: '50px',
    height: 'fit-content',
  },
  testSuiteListPanel: {
    flexGrow: 1,
  },
  testSuiteSecondPanel: {
    flexGrow: 3,
  },
  labelRoot: {
    display: 'flex',
    alignItems: 'center',
    padding: theme.spacing(0.5, 0),
  },
}));
