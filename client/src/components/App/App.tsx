import React, { FC, useEffect } from 'react';
import ThemeProvider from 'components/ThemeProvider';
import { BrowserRouter as Router } from 'react-router-dom';
import Header from 'components/Header';
import LandingPage from 'components/LandingPage';
import { Container } from '@material-ui/core';
import { Switch, Route, Redirect } from 'react-router-dom';
import { TestSuite, TestSession } from 'models/testSuiteModels';
import TestSessionWrapper from 'components/TestSuite/TestSessionWrapper';
import { getTestSuites } from 'api/TestSuitesApi';
import { postTestSessions } from 'api/TestSessionApi';

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
    return <div></div>;
  }

  return (
    <Router>
      <ThemeProvider>
        <Header />
        <Container maxWidth="lg">
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
        </Container>
      </ThemeProvider>
    </Router>
  );
};

export default App;
