import { Theme } from '@mui/material/styles';
import { makeStyles } from 'tss-react/mui';

export default makeStyles()((theme: Theme) => ({
  root: {
    backgroundColor: theme.palette.background.paper,
  },
  header: {
    padding: '8px 16px',
    fontWeight: 600,
    fontSize: '16px',
    borderBottom: `1px solid ${theme.palette.divider}`,
    backgroundColor: theme.palette.common.blueLightest,
    borderTopLeftRadius: '4px',
    borderTopRightRadius: '4px',
    display: 'flex',
    minHeight: '36.5px',
    alignItems: 'center',
  },
  headerText: {
    flexGrow: 1,
  },
  currentItem: {
    fontWeight: 600,
  },
  markdown: {
    p: {
      margin: 0,
    },
  },
}));
