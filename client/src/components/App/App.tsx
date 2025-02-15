import React, { FC, useEffect } from 'react';
import { Theme } from '@mui/material/styles';
import { SnackbarProvider } from 'notistack';
import { makeStyles } from 'tss-react/mui';
import { getTestSuites } from '~/api/TestSuitesApi';
import { TestSuite } from '~/models/testSuiteModels';
import { useAppStore } from '~/store/app';
import Router from '~/components/App/Router';
import SnackbarCloseButton from '~/components/_common/SnackbarCloseButton';

const useStyles = makeStyles<{ height: string }>()((theme: Theme, { height }) => ({
  container: {
    marginBottom: height,
    zIndex: `${theme.zIndex.snackbar} !important`,
  },
}));

const App: FC<unknown> = () => {
  const footerHeight = useAppStore((state) => state.footerHeight);
  const setFooterHeight = useAppStore((state) => state.setFooterHeight);
  const testSuites = useAppStore((state) => state.testSuites);
  const setTestSuites = useAppStore((state) => state.setTestSuites);
  const smallWindowThreshold = useAppStore((state) => state.smallWindowThreshold);
  const setWindowIsSmall = useAppStore((state) => state.setWindowIsSmall);

  const { classes } = useStyles({
    height: `${footerHeight}px`,
  });

  // Update UI on window resize
  useEffect(() => {
    window.addEventListener('resize', handleResize);
  });

  useEffect(() => {
    handleResize();
    getTestSuites()
      .then((testSuites: TestSuite[]) => {
        setTestSuites(testSuites);
      })
      .catch(() => {
        setTestSuites([]);
      });
  }, []);

  const handleResize = () => {
    if (window.innerWidth < smallWindowThreshold) {
      setWindowIsSmall(true);
      setFooterHeight(36);
    } else {
      setWindowIsSmall(false);
      setFooterHeight(56);
    }
  };

  return (
    <SnackbarProvider
      dense
      maxSnack={3}
      anchorOrigin={{
        vertical: 'bottom',
        horizontal: 'right',
      }}
      action={(id) => <SnackbarCloseButton id={id} />}
      classes={{
        containerAnchorOriginBottomRight: classes.container,
      }}
    >
      <Router testSuites={testSuites} />
    </SnackbarProvider>
  );
};

export default App;
