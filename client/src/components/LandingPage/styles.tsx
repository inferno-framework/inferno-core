import { makeStyles, Theme } from '@material-ui/core/styles';

export default makeStyles((theme: Theme) => ({
  container: {
    backgroundColor: theme.palette.common.white,
  },
  main: {
    display: 'flex',
    marginTop: '50px',
  },
  leftSide: {
    marginTop: '125px',
  },
  selectedItem: {
    backgroundColor: 'rgba(248, 139, 48, 0.42) !important',
  },
  getStarted: {
    marginTop: '100px',
    marginLeft: '50px',
    padding: '20px',
    borderRadius: '16px',
    display: 'flex',
    flexDirection: 'column',
    width: '400px',
  },
  startTestingButton: {
    fontWeight: 600,
  },
}));
