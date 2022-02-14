import { Theme } from '@mui/material/styles';
import makeStyles from '@mui/styles/makeStyles';

export default makeStyles((theme: Theme) => ({
  buttonWrapper: {
    display: 'flex',
    alignItems: 'center',
    visibility: 'hidden',
  },
  labelRoot: {
    display: 'flex',
    flex: '1 1 auto',
    alignItems: 'center',
    padding: theme.spacing(0.5, 0),
    '&:hover > $buttonWrapper': {
      visibility: 'visible',
    },
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
  labelRunButton: {
    width: '10px',
    height: '10px',
    marginRight: '5px',
  },
  testSuiteTreePanel: {
    width: '300px',
    overflowX: 'hidden',
    paddingBottom: '60px', // Prevent footer from blocking drawer
  },
  treeRoot: {
    '& $labelText': {
      textTransform: 'uppercase',
      fontWeight: 'bold',
    },
    padding: '8px 20px !important',
  },
}));
