import { SnackbarProvider } from 'notistack';
import React, { FC, useEffect } from 'react';
import { RouterProvider } from 'react-router-dom';
import { getTestSuites } from '~/api/TestSuitesApi';
import { router } from '~/components/App/Router';
import { TestSuite } from '~/models/testSuiteModels';
import { useAppStore } from '~/store/app';
import { useTestSessionStore } from '~/store/testSession';
import SnackbarCloseButton from 'components/_common/SnackbarCloseButton';
import lightTheme from '~/styles/theme';

const App: FC<unknown> = () => {
  const footerHeight = useAppStore((state) => state.footerHeight);
  const setFooterHeight = useAppStore((state) => state.setFooterHeight);
  const testSuites = useAppStore((state) => state.testSuites);
  const setTestSuites = useAppStore((state) => state.setTestSuites);
  const smallWindowThreshold = useAppStore((state) => state.smallWindowThreshold);
  const setWindowIsSmall = useAppStore((state) => state.setWindowIsSmall);
  const testRunInProgress = useTestSessionStore((state) => state.testRunInProgress);

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

  if (!testSuites || testSuites.length === 0) {
    return <></>;
  }

  return (
    <SnackbarProvider
      dense
      maxSnack={3}
      anchorOrigin={{
        vertical: 'bottom',
        horizontal: 'right',
      }}
      action={(id) => <SnackbarCloseButton id={id} />}
      style={{
        marginBottom: testRunInProgress ? `${72 + footerHeight}px` : `${footerHeight}px`,
        zIndex: lightTheme.zIndex.snackbar,
      }}
    >
      <RouterProvider router={router(testSuites)} />
    </SnackbarProvider>
  );
};

export default App;
