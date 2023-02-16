import React from 'react';
import { createBrowserRouter, Navigate } from 'react-router-dom';
import LandingPage from '~/components/LandingPage';
import SuiteOptionsPage from '~/components/SuiteOptionsPage';
import TestSessionWrapper from '~/components/TestSuite/TestSessionWrapper';
import { basePath } from '~/api/infernoApiService';
import Page from '~/components/App/Page';
import { TestSession, TestSuite } from '~/models/testSuiteModels';

export const router = (testSuites: TestSuite[], testSession?: TestSession) => {
  return createBrowserRouter(
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
};
