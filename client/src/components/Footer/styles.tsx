import { makeStyles, Theme } from '@material-ui/core/styles';

export default makeStyles((theme: Theme) => ({
  footer: {
    backgroundColor: theme.palette.common.grayLighter,
    position: 'fixed',
    width: '100%',
    zIndex: 'auto',
    alignItems: 'center',
    height: '50px',
    lineHeight: '50px',
    bottom: '0',
    display: 'flex',
    justifyContent: 'center',
  },
  footerElement: {
    flexGrow: 1,
    textAlign: 'center',
  },
}));
