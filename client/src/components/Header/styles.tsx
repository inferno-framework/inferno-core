import { makeStyles, Theme } from '@material-ui/core/styles';

export default makeStyles((theme: Theme) => ({
  appbar: {
    // Necessary to override default z-index value of appbar
    // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
    zIndex: `${theme.zIndex.drawer + 1} !important` as any,
  },
  logo: {
    objectFit: 'contain',
    height: '3.5em',
  },
}));
