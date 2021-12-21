import React, { FC, useEffect } from 'react';
import { BrowserRouter as Router, Redirect, Route, Switch } from 'react-router-dom';
import { StyledEngineProvider } from '@mui/material/styles';
import { postTestSessions } from 'api/TestSessionApi';
import { getTestSuites } from 'api/TestSuitesApi';
import Header from 'components/Header';
import LandingPage from 'components/LandingPage';
import TestSessionWrapper from 'components/TestSuite/TestSessionWrapper';
import ThemeProvider from 'components/ThemeProvider';
import { TestSession, TestSuite } from 'models/testSuiteModels';

const App: FC<unknown> = () => {
  const [testSuites, setTestSuites] = React.useState<TestSuite[]>();
  const [testSession, setTestSession] = React.useState<TestSession>();

  useEffect(() => {
    getTestSuites()
      .then((testSuites: TestSuite[]) => {
        setTestSuites(testSuites);
      })
      .catch((e) => {
        console.log(e);
      });
  }, []);

  useEffect(() => {
    if (testSuites && testSuites.length == 1) {
      postTestSessions(testSuites[0].id)
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

  if (!testSuites || (testSuites.length == 1 && !testSession)) {
    return <></>;
  }

  return (
    <Router>
      <StyledEngineProvider injectFirst>
        <ThemeProvider>
          <Header />
          <Switch>
            <Route exact path="/">
              {testSuites.length == 1 && testSession ? (
                <Redirect to={`/test_sessions/${testSession.id}`} />
              ) : (
                <LandingPage testSuites={testSuites} />
              )}
            </Route>
            <Route path="/test_sessions/:test_session_id">
              <TestSessionWrapper />
            </Route>
          </Switch>
        </ThemeProvider>
      </StyledEngineProvider>
    </Router>
  );
};

export default App;
