import React, { FC } from 'react';
import { Result, TestSession } from 'models/testSuiteModels';
import TestSessionComponent from './TestSession';
import { useParams } from 'react-router-dom';
import { getTestSession, getTestSessionResults } from 'api/infernoApiService';
import Alert from '@material-ui/lab/Alert';
import Backdrop from '@material-ui/core/Backdrop';

const TestSessionWrapper: FC<unknown> = () => {
  const [testSession, setTestSession] = React.useState<TestSession>();
  const [testResults, setTestResults] = React.useState<Result[]>();
  const [attemptedGetSession, setAttemptedGetSession] = React.useState(false);
  const [attemptedGetResults, setAttemptedGetResults] = React.useState(false);

  function tryGetTestSession(test_session_id: string) {
    getTestSession(test_session_id)
      .then((retrievedTestSession) => {
        if (retrievedTestSession) {
          setTestSession(retrievedTestSession);
        } else {
          console.log('failed to load test session');
        }
      })
      .catch((e) => console.log(e))
      .finally(() => setAttemptedGetSession(true));
  }

  function tryGetTestResults(test_session_id: string) {
    getTestSessionResults(test_session_id)
      .then((results) => {
        if (results) {
          setTestResults(results);
        } else {
          console.log('failed to load test session results');
        }
      })
      .catch((e) => console.log(e))
      .finally(() => setAttemptedGetResults(true));
  }

  if (testSession && testResults) {
    return <TestSessionComponent testSession={testSession} previousResults={testResults} />;
  } else if (attemptedGetSession && attemptedGetResults) {
    return (
      <div>
        <Alert severity="error">
          Failed to load test session data. Please make sure you entered the correct session id.
        </Alert>
      </div>
    );
  } else {
    const { test_session_id } = useParams<{ test_session_id: string }>();
    if (test_session_id) {
      if (!attemptedGetSession) {
        tryGetTestSession(test_session_id);
      }
      if (!attemptedGetResults) {
        tryGetTestResults(test_session_id);
      }
    }
    return <Backdrop open={true}></Backdrop>;
  }
};

export default TestSessionWrapper;
