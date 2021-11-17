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
    alignItems: 'center',
    padding: theme.spacing(0.5, 0),
    '&:hover > $buttonWrapper': {
      visibility: 'visible',
    },
  },
  labelText: {
    flexGrow: 1,
  },
  labelRunButton: {
    width: '10px',
    height: '10px',
    marginRight: '5px',
  },
  testSuiteTreePanel: {
    width: '400px',
  },
  treeRoot: {
    '& $labelText': {
      fontWeight: 600,
    },
    '& .MuiTreeItem-iconContainer': {
      display: 'none',
    },
  },
}));
