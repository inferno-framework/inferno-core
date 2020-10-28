import { makeStyles, Theme } from '@material-ui/core/styles';

export default makeStyles((theme: Theme) => ({
  root: {
    backgroundColor: theme.palette.background.paper,
  },
  testSuiteMain: {
    display: 'flex',
    marginTop: '50px',
    '& > *': {
      margin: '0 25px',
    },
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
