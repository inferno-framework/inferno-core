import React, { FC } from 'react';
import { Result, TestOutput, TestRun, TestSession } from 'models/testSuiteModels';
import TestSessionComponent from './TestSession';
import { useParams } from 'react-router-dom';
import Alert from '@material-ui/lab/Alert';
import Backdrop from '@material-ui/core/Backdrop';
import {
  getCurrentTestSessionResults,
  getLastTestRun,
  getTestSession,
  getTestSessionData,
} from 'api/TestSessionApi';

const TestSessionWrapper: FC<unknown> = () => {
  const [testRun, setTestRun] = React.useState<TestRun | null>(null);
  const [testSession, setTestSession] = React.useState<TestSession>();
  const [testResults, setTestResults] = React.useState<Result[]>();
  const [sessionData, setSessionData] = React.useState<TestOutput[]>();
  const [attemptedGetRun, setAttemptedGetRun] = React.useState(false);
  const [attemptedGetSession, setAttemptedGetSession] = React.useState(false);
  const [attemptedGetResults, setAttemptedGetResults] = React.useState(false);
  const [attemptedGetSessionData, setAttemptedSessionData] = React.useState(false);

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

  function tryGetTestRun(test_session_id: string) {
    getLastTestRun(test_session_id)
      .then((retrievedTestRun) => {
        if (retrievedTestRun) {
          setTestRun(retrievedTestRun);
        } else {
          setTestRun(null);
        }
      })
      .catch((e) => console.log(e))
      .finally(() => setAttemptedGetRun(true));
  }

  function tryGetTestResults(test_session_id: string) {
    getCurrentTestSessionResults(test_session_id)
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

  function tryGetSessionData(testSessionId: string) {
    getTestSessionData(testSessionId)
      .then((session_data) => {
        if (session_data) {
          setSessionData(session_data);
        } else {
          console.log('failed to load session data');
        }
      })
      .catch((e) => console.log(e))
      .finally(() => setAttemptedSessionData(true));
  }

  if (testSession && testResults && sessionData) {
    return (
      <TestSessionComponent
        testSession={testSession}
        previousResults={testResults}
        initialTestRun={testRun}
        initialSessionData={sessionData}
      />
    );
  } else if (attemptedGetSession && attemptedGetResults && attemptedGetSessionData) {
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
      if (!attemptedGetRun) {
        tryGetTestRun(test_session_id);
      }
      if (!attemptedGetSession) {
        tryGetTestSession(test_session_id);
      }
      if (!attemptedGetResults) {
        tryGetTestResults(test_session_id);
      }
      if (!attemptedGetSessionData) {
        tryGetSessionData(test_session_id);
      }
    }
    return <Backdrop open={true}></Backdrop>;
  }
};

export default TestSessionWrapper;
