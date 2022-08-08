import { Theme } from '@mui/material/styles';
import makeStyles from '@mui/styles/makeStyles';

export default makeStyles((theme: Theme) => ({
  labelRoot: {
    display: 'flex',
    flex: '1 1 auto',
    alignItems: 'center',
    padding: theme.spacing(0.5, 0),
  },
  labelText: {
    display: 'inline',
  },
  optionalLabel: {
    display: 'inline',
    fontStyle: 'italic',
    alignSelf: 'center',
    color: theme.palette.common.gray,
    paddingLeft: '8px',
  },
  shortId: {
    display: 'inline',
    fontWeight: 'bold',
    alignSelf: 'center',
    color: theme.palette.common.grayDarkest,
  },
  testSuiteTreePanel: {
    width: '300px',
    flexGrow: 1,
    overflowX: 'hidden',
  },
  testSuiteTree: {
    height: '100%',
    display: 'flex',
    flexDirection: 'column',
  },
  treeRoot: {
    '& $labelText': {
      textTransform: 'uppercase',
      fontWeight: 'bold',
    },
    padding: '8px 20px !important',
  },
}));
