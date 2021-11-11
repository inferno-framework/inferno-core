import MuiTreeItem from '@material-ui/lab/TreeItem';
import { withStyles } from '@material-ui/core/styles';

const TreeItem = withStyles({
  root: {
    '&.Mui-selected > .MuiTreeItem-content': {
      backgroundColor: 'rgba(248, 139, 48, 0.42) !important',
    },
    '&.MuiTreeItem-root > .MuiTreeItem-content:hover': {},
    '&.MuiTreeItem-root > .MuiTreeItem-content:hover > .MuiTreeItem-label': {},
    '@media (hover: none)': {},
  },
  selected: {},
  content: {},
  label: {},
})(MuiTreeItem);

export default TreeItem;
