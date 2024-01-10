import React from 'react';
import { createBrowserRouter } from 'react-router-dom';
import LandingPage from '~/components/LandingPage';
import SuiteOptionsPage from '~/components/SuiteOptionsPage';
// import TestSessionWrapper from '~/components/TestSuite/TestSessionWrapper';
import { basePath } from '~/api/infernoApiService';
import Page from '~/components/App/Page';
import { TestSuite } from '~/models/testSuiteModels';
import { Box } from '@mui/material';
import AppSkeleton from '~/components/Skeletons/AppSkeleton';
import HeaderSkeleton from '~/components/Skeletons/HeaderSkeleton';
import FooterSkeleton from '~/components/Skeletons/FooterSkeleton';

export const router = (testSuites: TestSuite[]) => {
  return createBrowserRouter(
    [
      {
        path: '/',
        element: (
          <Page title={`Inferno Test Suites`}>
            <LandingPage testSuites={testSuites} />
          </Page>
        ),
      },
      {
        path: ':test_suite_id',
        element: <Page title="Options" />,
        loader: ({ params }) => {
          if (testSuites.length === 0) return <></>;
          const suiteId: string = params.test_suite_id || '';
          const suite = testSuites.find((suite) => suite.id === suiteId);
          return <SuiteOptionsPage testSuite={suite} />;
        },
      },
      {
        // Title for TestSessionWrapper is set in the component
        // because testSession is not set at the time of render
        path: ':test_suite_id/:test_session_id',
        // element: <TestSessionWrapper />,
        element: (
          <Box display="flex" flexDirection="column" flexGrow="1" height="100%">
            <HeaderSkeleton />
            <AppSkeleton />
            <FooterSkeleton />
          </Box>
        ),
      },
    ],
    { basename: `/${basePath || ''}` }
  );
};
