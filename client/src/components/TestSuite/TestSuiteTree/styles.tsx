import { makeStyles, Theme } from '@material-ui/core/styles';

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
  selectedItem: {
    backgroundColor: 'rgba(248, 139, 48, 0.42) !important',
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
