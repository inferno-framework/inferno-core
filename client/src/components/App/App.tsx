import React, { FC, useEffect } from 'react';
import { createBrowserRouter, RouterProvider, Navigate } from 'react-router-dom';
import { StyledEngineProvider } from '@mui/material/styles';
import { postTestSessions } from '~/api/TestSessionApi';
import { getTestSuites } from '~/api/TestSuitesApi';
import LandingPage from '~/components/LandingPage';
import SuiteOptionsPage from '~/components/SuiteOptionsPage';
import TestSessionWrapper from '~/components/TestSuite/TestSessionWrapper';
import ThemeProvider from '~/components/ThemeProvider';
import { TestSession, TestSuite } from '~/models/testSuiteModels';
import { basePath } from '~/api/infernoApiService';

import { useAppStore } from '~/store/app';
import Page from './Page';

const App: FC<unknown> = () => {
  const setFooterHeight = useAppStore((state) => state.setFooterHeight);
  const testSuites = useAppStore((state) => state.testSuites);
  const setTestSuites = useAppStore((state) => state.setTestSuites);
  const testSession = useAppStore((state) => state.testSession);
  const setTestSession = useAppStore((state) => state.setTestSession);
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
      .catch((e) => {
        console.error(e);
      });
  }, []);

  useEffect(() => {
    if (testSuites && testSuites.length === 1) {
      postTestSessions(testSuites[0].id, null, null)
        .then((testSession: TestSession | null) => {
          if (testSession && testSession.test_suite) {
            setTestSession(testSession);
          }
        })
        .catch((e) => {
          console.error(e);
        });
    }
  }, [testSuites]);

  const handleResize = () => {
    if (window.innerWidth < smallWindowThreshold) {
      setWindowIsSmall(true);
      setFooterHeight(36);
    } else {
      setWindowIsSmall(false);
      setFooterHeight(56);
    }
  };

  const router = createBrowserRouter(
    [
      {
        path: '/',
        element:
          testSuites.length === 1 && testSession ? (
            <Navigate to={`/test_sessions/${testSession.id}`} />
          ) : (
            <Page title={`Inferno Test Suites`}>
              <LandingPage testSuites={testSuites} />
            </Page>
          ),
      },
      {
        path: ':test_suite_id',
        element: <Page title="Options" />,
        loader: ({ params }) => {
          const suiteId: string = params.test_suite_id || '';
          const suite = testSuites.find((suite) => suite.id === suiteId);
          return <SuiteOptionsPage testSuite={suite} />;
        },
      },
      {
        // Title for TestSessionWrapper is set in the component
        // because testSession is not set at the time of render
        path: 'test_sessions/:test_session_id',
        element: <TestSessionWrapper />,
      },
    ],
    { basename: `/${basePath}` }
  );

  if (!testSuites || (testSuites.length === 1 && !testSession)) {
    return <></>;
  }

  return (
    <StyledEngineProvider injectFirst>
      <ThemeProvider>
        <RouterProvider router={router} />
      </ThemeProvider>
    </StyledEngineProvider>
  );
};

export default App;
