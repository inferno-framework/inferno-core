import { Theme } from '@mui/material/styles';

import makeStyles from '@mui/styles/makeStyles';

export default makeStyles((theme: Theme) => ({
  container: {
    backgroundColor: theme.palette.common.white,
  },
  main: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-evenly',
    overflow: 'hidden',
    marginBottom: '80px',
  },
  selectedItem: {
    backgroundColor: 'rgba(248, 139, 48, 0.2) !important',
  },
  startTesting: {
    margin: '20px',
    padding: '20px 20px 0 20px',
    borderRadius: '16px',
    overflow: 'auto',
  },
  startTestingButton: {
    fontWeight: 600,
    margin: '20px 0',
  },
}));
