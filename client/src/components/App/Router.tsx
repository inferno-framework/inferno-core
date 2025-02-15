import React, { FC } from 'react';
import { BrowserRouter, Routes, Route } from 'react-router';
import Page from '~/components/App/Page';
import LandingPage from '~/components/LandingPage';
import SuiteOptionsPage from '~/components/SuiteOptionsPage';
import TestSessionWrapper from '~/components/TestSuite/TestSessionWrapper';
import LandingPageSkeleton from '~/components/Skeletons/LandingPageSkeleton';
import SuiteOptionsPageSkeleton from '~/components/Skeletons/SuiteOptionsPageSkeleton';
import { basePath } from '~/api/infernoApiService';
import { TestSuite } from '~/models/testSuiteModels';

export interface RouterProps {
  testSuites: TestSuite[];
}

const Router: FC<RouterProps> = ({ testSuites }) => {
  const testSuitesExist = !!testSuites && testSuites.length > 0;

  return (
    <BrowserRouter basename={`/${basePath || ''}`}>
      <Routes>
        <Route
          path="/"
          element={
            <Page title={`Inferno Test Suites`}>
              {testSuitesExist ? <LandingPage testSuites={testSuites} /> : <LandingPageSkeleton />}
            </Page>
          }
        />
        <Route
          path=":test_suite_id"
          element={<Page title="Options" />}
          loader={({ params }) => {
            if (!testSuitesExist) return <SuiteOptionsPageSkeleton />;
            const suiteId: string = params.test_suite_id || '';
            const suite = testSuites.find((suite) => suite.id === suiteId);
            return suite ? <SuiteOptionsPage testSuite={suite} /> : <SuiteOptionsPageSkeleton />;
          }}
        />
        {/*
         * Title for TestSessionWrapper is set in the component
         * because testSession is not set at the time of render
         */}
        <Route path=":test_suite_id/:test_session_id" element={<TestSessionWrapper />} />
      </Routes>
    </BrowserRouter>
  );
};

export default Router;
