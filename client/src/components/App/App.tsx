import React, { FC, useEffect } from 'react';
import { BrowserRouter as Router, Redirect, Route, Switch } from 'react-router-dom';
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

const App: FC<unknown> = () => {
  const testSuites = useAppStore((state) => state.testSuites);
  const setTestSuites = useAppStore((state) => state.setTestSuites);
  const testSession = useAppStore((state) => state.testSession);
  const setTestSession = useAppStore((state) => state.setTestSession);
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
        console.log(e);
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
          console.log(e);
        });
    }
  }, [testSuites]);

  function handleResize() {
    setWindowIsSmall(window.innerWidth < 800);
  }

  if (!testSuites || (testSuites.length === 1 && !testSession)) {
    return <></>;
  }

  return (
    <Router basename={basePath}>
      <StyledEngineProvider injectFirst>
        <ThemeProvider>
          <Switch>
            <Route exact path="/">
              {testSuites.length === 1 && testSession ? (
                <Redirect to={`/test_sessions/${testSession.id}`} />
              ) : (
                <LandingPage testSuites={testSuites} />
              )}
            </Route>
            <Route path="/test_sessions/:test_session_id">
              <TestSessionWrapper />
            </Route>
            <Route path="/:test_suite_id">
              {testSuites.length > 1 && <SuiteOptionsPage testSuites={testSuites} />}
            </Route>
          </Switch>
        </ThemeProvider>
      </StyledEngineProvider>
    </Router>
  );
};

export default App;
