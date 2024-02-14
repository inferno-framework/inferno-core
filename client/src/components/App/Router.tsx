import React from 'react';
import { createBrowserRouter } from 'react-router-dom';
import Page from '~/components/App/Page';
import LandingPage from '~/components/LandingPage';
import SuiteOptionsPage from '~/components/SuiteOptionsPage';
import TestSessionWrapper from '~/components/TestSuite/TestSessionWrapper';
import LandingPageSkeleton from '~/components/Skeletons/LandingPageSkeleton';
import SelectionSkeleton from '~/components/Skeletons/SelectionSkeletion';
import { basePath } from '~/api/infernoApiService';
import { TestSuite } from '~/models/testSuiteModels';

export const router = (testSuites: TestSuite[]) => {
  const testSuitesExist = !!testSuites && testSuites.length > 0;
  return createBrowserRouter(
    [
      {
        path: '/',
        element: (
          <Page title={`Inferno Test Suites`}>
            {testSuitesExist ? <LandingPage testSuites={testSuites} /> : <LandingPageSkeleton />}
          </Page>
        ),
      },
      {
        path: ':test_suite_id',
        element: <Page title="Options" />,
        loader: ({ params }) => {
          if (!testSuitesExist) return <SelectionSkeleton />;
          const suiteId: string = params.test_suite_id || '';
          const suite = testSuites.find((suite) => suite.id === suiteId);
          return testSuitesExist && suite ? (
            <SuiteOptionsPage testSuite={suite} />
          ) : (
            <SelectionSkeleton />
          );
        },
      },
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
