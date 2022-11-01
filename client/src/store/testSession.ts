import create from 'zustand';
import { devtoolsInDev } from './devtools';

type TestSessionStore = {
  testRunInProgress: boolean;
  setTestRunInProgress: (testRunInProgress: boolean) => void;
};

export const useTestSessionStore = create<TestSessionStore>(
  devtoolsInDev((set, _get) => ({
    testRunInProgress: false,
    setTestRunInProgress: (testRunInProgress: boolean) =>
      set({ testRunInProgress: testRunInProgress }),
  }))
);
