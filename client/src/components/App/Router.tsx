import React from 'react';
import { createBrowserRouter } from 'react-router-dom';
import LandingPage from '~/components/LandingPage';
import TestSessionWrapper from '~/components/TestSuite/TestSessionWrapper';
import { basePath } from '~/api/infernoApiService';
import Page from '~/components/App/Page';
import { TestSuite } from '~/models/testSuiteModels';

export const router = (testSuites: TestSuite[]) => {
  const landingPageRoutes = ['/', ':test_suite_id'].map((route) => ({
    path: route,
    element: (
      <Page title={`Inferno Test Suites`}>
        <LandingPage testSuites={testSuites} />
      </Page>
    ),
  }));

  return createBrowserRouter(
    [
      ...landingPageRoutes,
      {
        // Title for TestSessionWrapper is set in the component
        // because testSession is not set at the time of render
        path: ':test_suite_id/:test_session_id',
        element: <TestSessionWrapper />,
      },
    ],
    { basename: `/${basePath || ''}` }
  );
};
