import { makeStyles, Theme } from '@material-ui/core/styles';

export default makeStyles((theme: Theme) => ({
  labelRoot: {
    display: 'flex',
    alignItems: 'center',
    padding: theme.spacing(0.5, 0),
    '&:hover > $labelRunButton': {
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
    visibility: 'hidden',
  },
  testSuiteTreePanel: {
    height: 'fit-content',
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
