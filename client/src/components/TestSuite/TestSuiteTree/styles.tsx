import { Theme } from '@mui/material/styles';
import makeStyles from '@mui/styles/makeStyles';

export default makeStyles((theme: Theme) => ({
  labelRoot: {
    display: 'flex',
    flex: '1 1 auto',
    alignItems: 'center',
    padding: theme.spacing(0.5, 0),
  },
  labelContainer: {
    display: 'inline',
    width: '100%',
  },
  labelText: {
    display: 'inline',
  },
  optionalLabel: {
    display: 'inline',
    fontStyle: 'italic',
    alignSelf: 'center',
    color: theme.palette.common.grayLight,
    paddingLeft: '8px',
  },
  shortId: {
    display: 'inline',
    fontWeight: 'bold',
    alignSelf: 'center',
    paddingRight: '4px',
    color: theme.palette.common.grayVeryDark,
  },
  testSuiteTreePanel: {
    width: '300px',
    overflowX: 'hidden',
  },
  treeRoot: {
    '& $labelText': {
      textTransform: 'uppercase',
      fontWeight: 'bold',
    },
    padding: '8px 20px !important',
  },
}));
