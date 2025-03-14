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
          const testSuitesExist = !!testSuites && testSuites.length > 0;
          if (testSuitesExist) {
            return <LandingPage testSuites={testSuites} />;
          } else {
            return <LandingPageSkeleton />;
          }
        },
        element: <Page title={`Inferno Test Suites`} />,
      },
      {
        path: ':test_suite_id',
        element: <Page title="Options" />,
        loader: ({ params }) => {
          const testSuitesExist = !!testSuites && testSuites.length > 0;
          if (!testSuitesExist) return <SuiteOptionsPageSkeleton />;
          const suiteId: string = params.test_suite_id || '';
          const suite = testSuites.find((suite) => suite.id === suiteId);
          return suite ? <SuiteOptionsPage testSuite={suite} /> : <SuiteOptionsPageSkeleton />;
        },
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
