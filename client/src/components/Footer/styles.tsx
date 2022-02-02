import { Theme } from '@mui/material/styles';

import makeStyles from '@mui/styles/makeStyles';

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
  logo: {
    objectFit: 'contain',
    height: '2.5em',
  },
}));
