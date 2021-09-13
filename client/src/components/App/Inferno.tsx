import React, { FC, useEffect } from 'react';
import Header from 'components/Header';
import LandingPage from 'components/LandingPage';
import { Container } from '@material-ui/core';
import { Switch, Route } from 'react-router-dom';
import TestSessionWrapper from 'components/TestSuite/TestSessionWrapper';
import { TestSuite, TestSession } from 'models/testSuiteModels';
import { getTestSuites } from 'api/TestSuitesApi';
import { postTestSessions } from 'api/TestSessionApi';
import { useHistory } from 'react-router-dom';

const Inferno: FC<unknown> = () => {
  const [testSuites, setTestSuites] = React.useState<TestSuite[]>();
  const [testSuiteChosen, setTestSuiteChosen] = React.useState('');
  const history = useHistory();

  useEffect(() => {
    if (!testSuites) {
      getTestSuites()
        .then((testSuites: TestSuite[]) => {
          setTestSuites(testSuites);
        })
        .catch((e) => {
          console.log(e);
        });
    } else if (testSuites.length === 1) {
      if (testSuiteChosen === '') {
        setTestSuiteChosen(testSuites[0].id);
      } else {
        createTestSession();
      }
    }
  });

  function createTestSession(): void {
    postTestSessions(testSuiteChosen)
      .then((testSession: TestSession | null) => {
        if (testSession && testSession.test_suite) {
          history.push('test_sessions/' + testSession.id);
        }
      })
      .catch((e) => {
        console.log(e);
      });
  }

  return (
    <div>
      <Header setTestSuiteChosen={setTestSuiteChosen} />
      <Container maxWidth="lg">
        <Switch>
          <Route exact path="/">
            <LandingPage
              testSuites={testSuites}
              createTestSession={createTestSession}
              testSuiteChosen={testSuiteChosen}
              setTestSuiteChosen={setTestSuiteChosen}
            />
          </Route>
          <Route path="/test_sessions/:test_session_id">
            <TestSessionWrapper />
          </Route>
        </Switch>
      </Container>
    </div>
  );
};

export default Inferno;
