import { makeStyles, Theme } from '@material-ui/core/styles';

export default makeStyles((theme: Theme) => ({
  container: {
    backgroundColor: theme.palette.common.white,
  },
  main: {
    marginTop: '160px',
    padding: '0 60px',
  },
  selectedItem: {
    backgroundColor: 'rgba(248, 139, 48, 0.42) !important',
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
