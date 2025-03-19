import React from 'react';
import { createBrowserRouter } from 'react-router';
import Page from '~/components/App/Page';
import LandingPage from '~/components/LandingPage';
import SuiteOptionsPage from '~/components/SuiteOptionsPage';
import TestSessionWrapper from '~/components/TestSuite/TestSessionWrapper';
import LandingPageSkeleton from '~/components/Skeletons/LandingPageSkeleton';
import SuiteOptionsPageSkeleton from '~/components/Skeletons/SuiteOptionsPageSkeleton';
import { basePath } from '~/api/infernoApiService';
import { TestSuite } from '~/models/testSuiteModels';

export const router = (testSuites: TestSuite[]) => {
  return createBrowserRouter(
    [
      {
        path: '/',
        loader: () => {
          return !!testSuites && testSuites.length > 0 ? (
            <LandingPage testSuites={testSuites} />
          ) : (
            <LandingPageSkeleton />
          );
        },
        element: <Page title={`Inferno Test Suites`} />,
        hydrateFallbackElement: <LandingPageSkeleton />,
      },
      {
        path: ':test_suite_id',
        element: <Page title="Options" />,
        loader: ({ params }) => {
          if (!testSuites || testSuites.length === 0) return <SuiteOptionsPageSkeleton />;
          const suiteId: string = params.test_suite_id || '';
          const suite = testSuites.find((suite) => suite.id === suiteId);
          return suite ? <SuiteOptionsPage testSuite={suite} /> : <SuiteOptionsPageSkeleton />;
        },
        hydrateFallbackElement: <SuiteOptionsPageSkeleton />,
      },
      {
        // Title for TestSessionWrapper is set in the component
        // because testSession is not set at the time of render
        path: ':test_suite_id/:test_session_id',
        element: <TestSessionWrapper />,
      },
    ],
    { basename: `/${basePath || ''}` },
  );
};
