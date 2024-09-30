// Necessary to override default z-index value of appbar

import { Theme } from '@mui/material/styles';
import { makeStyles } from 'tss-react/mui';

export default makeStyles()((theme: Theme) => ({
  footer: {
    display: 'flex',
    width: '100%',
    overflow: 'auto',
    borderTop: `1px ${theme.palette.divider} solid`,
    bottom: 0,
    '@media print': {
      display: 'none',
    },
  },
  logo: {
    objectFit: 'contain',
    height: '2.5em',
    padding: '0 8px 0 0',
  },
  mobileLogo: {
    objectFit: 'contain',
    height: '1.7em',
    padding: '4px 8px 0 0',
  },
  logoText: {
    fontStyle: 'italic',
    textTransform: 'uppercase',
    width: 'max-content',
  },
  link: {
    fontWeight: 'bolder',
    width: 'max-content',
  },
}));
