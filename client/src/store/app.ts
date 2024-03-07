import { create } from 'zustand';
import { devtoolsInDev } from './devtools';

import { TestSuite, TestSession } from '~/models/testSuiteModels';

type AppStore = {
  footerHeight: number;
  headerHeight: number;
  testSuites: TestSuite[];
  testSession: TestSession | undefined;
  smallWindowThreshold: number;
  windowIsSmall: boolean | undefined;
  setFooterHeight: (footerHeight: number) => void;
  setTestSuites: (testSuites: TestSuite[]) => void;
  setTestSession: (testSession: TestSession | undefined) => void;
  setWindowIsSmall: (windowIsSmall: boolean) => void;
};

// this store is for global state, things at the top level
// other stores can be attached to child components
export const useAppStore = create<AppStore>()(
  devtoolsInDev(
    (set, _get): AppStore => ({
      footerHeight: 56, // default height, small window height is 36
      headerHeight: 64,
      testSuites: [] as TestSuite[],
      testSession: undefined,
      smallWindowThreshold: 1000,
      windowIsSmall: undefined,
      setFooterHeight: (footerHeight: number) => set({ footerHeight: footerHeight }),
      setTestSuites: (testSuites: TestSuite[]) => set({ testSuites: testSuites }),
      setTestSession: (testSession: TestSession | undefined) => set({ testSession: testSession }),
      setWindowIsSmall: (windowIsSmall: boolean | undefined) =>
        set({ windowIsSmall: windowIsSmall }),
    })
  )
);
