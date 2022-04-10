import { Theme } from '@mui/material/styles';

import makeStyles from '@mui/styles/makeStyles';

export default makeStyles((theme: Theme) => ({
  container: {
    backgroundColor: theme.palette.common.white,
  },
  main: {
    height: '100%',
    display: 'flex',
    padding: '0 60px',
  },
  selectedItem: {
    backgroundColor: 'rgba(248, 139, 48, 0.2) !important',
  },
  getStarted: {
    marginTop: '20px',
    padding: '20px',
    borderRadius: '16px',
    width: '400px',
  },
  startTestingButton: {
    fontWeight: 600,
  },
}));
