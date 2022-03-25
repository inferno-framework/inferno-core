import { Theme } from '@mui/material/styles';
import makeStyles from '@mui/styles/makeStyles';

export default makeStyles((theme: Theme) => ({
  root: {
    backgroundColor: theme.palette.background.paper,
  },
  configCardHeader: {
    padding: '8px 16px',
    fontWeight: 600,
    fontSize: '16px',
    borderBottom: '1px solid rgba(0,0,0,.12)',
    backgroundColor: theme.palette.common.blueGrayLightest,
    borderTopLeftRadius: '4px',
    borderTopRightRadius: '4px',
    display: 'flex',
    minHeight: '36.5px',
    alignItems: 'center',
  },
  configCardHeaderText: {
    flexGrow: 1,
  },
  currentItem: {
    fontWeight: 600,
  },
}));
