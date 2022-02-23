import React, { FC, useEffect } from 'react';
import useStyles from './styles';
import { Result, TestOutput, TestRun, TestSession } from 'models/testSuiteModels';
import TestSessionComponent from './TestSession';
import { useParams } from 'react-router-dom';
import { Alert, Backdrop, Box } from '@mui/material';
import Header from 'components/Header';
import Footer from 'components/Footer';
import {
  getCurrentTestSessionResults,
  getLastTestRun,
  getTestSession,
  getTestSessionData,
} from 'api/TestSessionApi';
import { getCoreVersion } from 'api/VersionsApi';

const TestSessionWrapper: FC<unknown> = () => {
  const styles = useStyles();
  const [testRun, setTestRun] = React.useState<TestRun | null>(null);
  const [testSession, setTestSession] = React.useState<TestSession>();
  const [testResults, setTestResults] = React.useState<Result[]>();
  const [sessionData, setSessionData] = React.useState<Map<string, unknown>>(new Map());
  const [attemptedGetRun, setAttemptedGetRun] = React.useState(false);
  const [attemptedGetSession, setAttemptedGetSession] = React.useState(false);
  const [attemptedGetResults, setAttemptedGetResults] = React.useState(false);
  const [attemptedGetSessionData, setAttemptedSessionData] = React.useState(false);
  const [attemptingFetchSessionInfo, setAttemptingFetchSessionInfo] = React.useState(false);
  const [coreVersion, setCoreVersion] = React.useState<string>('');

  useEffect(() => {
    getCoreVersion()
      .then((version: string) => {
        setCoreVersion(version);
      })
      .catch((e) => {
        console.log(e);
      });
  }, []);

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
          session_data?.forEach((initialSessionData: TestOutput) => {
            if (initialSessionData.value) {
              sessionData.set(initialSessionData.name, initialSessionData.value);
            }
          });
          setSessionData(new Map(sessionData));
        } else {
          console.log('failed to load session data');
        }
      })
      .catch((e) => console.log(e))
      .finally(() => setAttemptedSessionData(true));
  }

  if (testSession && testResults && sessionData) {
    return (
      <Box className={styles.testSessionContainer}>
        <Header
          suiteTitle={testSession.test_suite.title}
          suiteVersion={testSession.test_suite.version}
          presets={testSession.test_suite.presets}
          getSessionData={tryGetSessionData}
          testSessionId={testSession.id}
        />
        <TestSessionComponent
          testSession={testSession}
          previousResults={testResults}
          initialTestRun={testRun}
          sessionData={sessionData}
          setSessionData={setSessionData}
        />
        <Footer version={coreVersion} />
      </Box>
    );
  } else if (
    attemptedGetSession &&
    attemptedGetResults &&
    attemptedGetSessionData &&
    attemptedGetRun
  ) {
    return (
      <div>
        <Alert severity="error">
          Failed to load test session data. Please make sure you entered the correct session id.
        </Alert>
      </div>
    );
  } else {
    const { test_session_id } = useParams<{ test_session_id: string }>();
    if (test_session_id && !attemptingFetchSessionInfo) {
      setAttemptingFetchSessionInfo(true);
      tryGetTestRun(test_session_id);
      tryGetTestSession(test_session_id);
      tryGetTestResults(test_session_id);
      tryGetSessionData(test_session_id);
    }
    return <Backdrop open={true}></Backdrop>;
  }
};

export default TestSessionWrapper;
