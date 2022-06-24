import create from 'zustand';
import { devtoolsInDev } from './devtools';

import { TestSuite, TestSession } from '../models/testSuiteModels';

type AppStore = {
  testSuites: TestSuite[];
  testSession: TestSession | undefined;
  windowIsSmall: boolean | undefined;
  setTestSuites: (testSuites: TestSuite[]) => void;
  setTestSession: (testSession: TestSession | undefined) => void;
  setWindowIsSmall: (windowIsSmall: boolean) => void;
};

// this store is for global state, things at the top level
// other stores can be attached to child components
export const useAppStore = create<AppStore>(
  devtoolsInDev((set, _get) => ({
    testSuites: [] as TestSuite[],
    testSession: undefined,
    windowIsSmall: undefined,
    setTestSuites: (testSuites: TestSuite[]) => set({ testSuites: testSuites }),
    setTestSession: (testSession: TestSession | undefined) => set({ testSession: testSession }),
    setWindowIsSmall: (windowIsSmall: boolean | undefined) => set({ windowIsSmall: windowIsSmall }),
  }))
);
