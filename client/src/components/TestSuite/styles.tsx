import { Theme } from '@mui/material/styles';

import makeStyles from '@mui/styles/makeStyles';

const bannerHeight = () => {
  const bannerElementHeight = document.getElementsByClassName('banner')[0]?.clientHeight;
  if (bannerElementHeight === undefined || bannerElementHeight === null) {
    return 0;
  }

  return bannerElementHeight;
};

export default makeStyles((theme: Theme) => ({
  root: {
    backgroundColor: theme.palette.background.paper,
  },
  contentContainer: {
    flexGrow: 1,
    padding: '24px 48px',
    overflowX: 'hidden',
    overflow: 'auto',
    '@media print': {
      margin: 0,
      position: 'absolute',
      left: 0,
      right: 0,
      top: '51px', // height of footer
    },
  },
  drawer: {
    display: 'flex',
    flexGrow: 1,
    '@media print': {
      display: 'none',
    },
  },
  testSuiteMain: {
    display: 'flex',
    flexGrow: 1,
    overflow: 'hidden',
    maxHeight: `calc(100vh - ${bannerHeight()}px)`,
    '@media print': {
      maxHeight: 'unset',
    },
  },
  drawerPaper: {
    flexShrink: 0,
    width: '300px',
    position: 'static',
  },
  swipeableDrawerHeight: {
    marginTop: `${bannerHeight()}px`,
    height: `calc(100% - ${bannerHeight()}px)`,
  },
  hidePrint: {
    '@media print': {
      display: 'none',
    },
  },
}));
