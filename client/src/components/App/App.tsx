import React, { FC, useEffect } from 'react';
import { RouterProvider } from 'react-router-dom';
import { StyledEngineProvider } from '@mui/material/styles';
import { getTestSuites } from '~/api/TestSuitesApi';
import { router } from '~/components/App/Router';
import ThemeProvider from '~/components/ThemeProvider';
import { TestSuite } from '~/models/testSuiteModels';
import { useAppStore } from '~/store/app';

const App: FC<unknown> = () => {
  const setFooterHeight = useAppStore((state) => state.setFooterHeight);
  const testSuites = useAppStore((state) => state.testSuites);
  const setTestSuites = useAppStore((state) => state.setTestSuites);
  const smallWindowThreshold = useAppStore((state) => state.smallWindowThreshold);
  const setWindowIsSmall = useAppStore((state) => state.setWindowIsSmall);

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
    <StyledEngineProvider injectFirst>
      <ThemeProvider>
        <RouterProvider router={router(testSuites)} />
      </ThemeProvider>
    </StyledEngineProvider>
  );
};

export default App;
