import React, { FC, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import { Alert, Box, Fade } from '@mui/material';
import {
  Result,
  SuiteOption,
  SuiteOptionChoice,
  TestOutput,
  TestRun,
  TestSession,
  TestSuite,
} from '~/models/testSuiteModels';
import AppSkeleton from '~/components/Skeletons/AppSkeleton';
import Footer from '~/components/Footer';
import FooterSkeleton from '~/components/Skeletons/FooterSkeleton';
import Header from '~/components/Header';
import HeaderSkeleton from '~/components/Skeletons/HeaderSkeleton';
import TestSessionComponent from '~/components/TestSuite/TestSession';
import {
  getCurrentTestSessionResults,
  getLastTestRun,
  getTestSession,
  getTestSessionData,
} from '~/api/TestSessionApi';
import { getCoreVersion } from '~/api/VersionsApi';
import { useSnackbar } from 'notistack';
import { useAppStore } from '~/store/app';

const TestSessionWrapper: FC<unknown> = () => {
  const { enqueueSnackbar } = useSnackbar();
  const testSuites = useAppStore((state) => state.testSuites);
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
  const [drawerOpen, setDrawerOpen] = React.useState(false);

  useEffect(() => {
    getCoreVersion()
      .then((version: string) => {
        setCoreVersion(version);
      })
      .catch(() => {
        setCoreVersion('');
      });
  }, []);

  function tryGetTestSession(test_session_id: string) {
    getTestSession(test_session_id)
      .then((retrievedTestSession) => {
        if (retrievedTestSession) {
          setTestSession(retrievedTestSession);
        } else {
          enqueueSnackbar('Failed to load test session', { variant: 'error' });
        }
      })
      .catch((e: Error) => {
        enqueueSnackbar(`Error while getting test session: ${e.message}`, { variant: 'error' });
      })
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
      .catch(() => {
        // Assume no prior test run exists, do nothing
      })
      .finally(() => setAttemptedGetRun(true));
  }

  function tryGetTestResults(test_session_id: string) {
    getCurrentTestSessionResults(test_session_id)
      .then((results) => {
        if (results) {
          setTestResults(results);
        } else {
          enqueueSnackbar('Failed to load test session results', { variant: 'error' });
        }
      })
      .catch((e: Error) => {
        enqueueSnackbar(`Error while getting test results: ${e.message}`, { variant: 'error' });
      })
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
          enqueueSnackbar('Failed to load session data', { variant: 'error' });
        }
      })
      .catch((e: Error) => {
        enqueueSnackbar(`Error getting session data: ${e.message}`, { variant: 'error' });
      })
      .finally(() => setAttemptedSessionData(true));
  }

  const toggleDrawer = (newDrawerOpen: boolean) => {
    setDrawerOpen(newDrawerOpen);
  };

  /* Meta tags for link unfurling */
  const renderMetaTags = (session: TestSession) => {
    // Set the page title when testSession data is loaded
    const suiteName = session?.test_suite.short_title || session?.test_suite.title;
    const titlePrepend = suiteName ? `${suiteName} ` : '';
    const title = `${titlePrepend}Test Session`;
    document.title = title;
    const description =
      session.test_suite.short_description || session.test_suite.description || '';
    return (
      <>
        <title>{title}</title>
        <meta name="og:title" content={title} />
        <meta name="twitter:title" content={title} />
        <meta name="description" content={description} />
        <meta name="og:description" content={description} />
        <meta name="twitter:description" content={description} />
      </>
    );
  };

  if (testSession && testResults && sessionData) {
    // Temporary stopgap to get labels until full choice data is passed to TestSessionWrapper
    const suiteOptionChoices: { [key: string]: SuiteOptionChoice[] } | undefined = testSuites
      ?.find((suite: TestSuite) => suite.id === testSession.test_suite_id)
      ?.suite_options?.reduce(
        (acc, option) => ({ ...acc, [option.id]: option.list_options || [] }),
        {},
      );
    const parsedOptions = suiteOptionChoices
      ? testSession.suite_options
          ?.map((option: SuiteOption) =>
            suiteOptionChoices[option.id].filter(
              (choice: SuiteOptionChoice) => choice.value === option.value,
            ),
          )
          .flat()
          .filter((v) => v) // Remove empty values
      : [];

    return (
      <Fade in={true}>
        <Box display="flex" flexDirection="column" flexGrow="1" height="100%">
          {renderMetaTags(testSession)}
          <Header
            suiteId={testSession.test_suite.id}
            suiteTitle={testSession.test_suite.title}
            suiteVersion={testSession.test_suite.version}
            suiteOptions={parsedOptions}
            drawerOpen={drawerOpen}
            toggleDrawer={toggleDrawer}
          />
          <TestSessionComponent
            testSession={testSession}
            previousResults={testResults}
            initialTestRun={testRun}
            sessionData={sessionData}
            suiteOptions={parsedOptions}
            drawerOpen={drawerOpen}
            setSessionData={setSessionData}
            getSessionData={tryGetSessionData}
            toggleDrawer={toggleDrawer}
          />
          <Footer version={coreVersion} linkList={testSession.test_suite.links} />
        </Box>
      </Fade>
    );
  } else if (
    attemptedGetSession &&
    attemptedGetResults &&
    attemptedGetSessionData &&
    attemptedGetRun
  ) {
    return (
      <Box display="flex" flexDirection="column" flexGrow="1" height="100%">
        <Alert severity="error">
          Failed to load test session data. Please make sure you entered the correct session id.
        </Alert>
        <HeaderSkeleton />
        <AppSkeleton />
        <FooterSkeleton />
      </Box>
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
    return (
      <Box display="flex" flexDirection="column" flexGrow="1" height="100%">
        <HeaderSkeleton />
        <AppSkeleton />
        <FooterSkeleton />
      </Box>
    );
  }
};

export default TestSessionWrapper;
