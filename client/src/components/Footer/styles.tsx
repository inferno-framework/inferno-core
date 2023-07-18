// Necessary to override default z-index value of appbar
/* eslint-disable @typescript-eslint/no-explicit-any */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */

import { Theme } from '@mui/material/styles';
import { makeStyles } from 'tss-react/mui';

export default makeStyles()((theme: Theme) => ({
  footer: {
    width: '100%',
    overflow: 'auto',
    zIndex: `${theme.zIndex.drawer + 1} !important` as any,
    backgroundColor: theme.palette.common.orangeLightest,
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
  logoLink: {
    fontStyle: 'normal',
    color: theme.palette.secondary.main,
  },
  linkText: {
    color: theme.palette.secondary.main,
  },
}));
