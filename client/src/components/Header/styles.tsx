import { makeStyles, Theme } from '@material-ui/core/styles';

export default makeStyles((theme: Theme) => ({
  header: {
    color: theme.palette.primary.main,
    height: '5em',
    padding: '0.25em 0.25em',
    display: 'flex',
    alignItems: 'center',
    backgroundColor: theme.palette.common.white,
  },
  logo: {
    objectFit: 'contain',
    height: '4em',
  },
}));
