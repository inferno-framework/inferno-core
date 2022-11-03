import create from 'zustand';
import { devtoolsInDev } from './devtools';

type TestSessionStore = {
  testRunId: string | undefined;
  testRunInProgress: boolean;
  setTestRunId: (testRunId: string | undefined) => void;
  setTestRunInProgress: (testRunInProgress: boolean) => void;
};

export const useTestSessionStore = create<TestSessionStore>(
  devtoolsInDev((set, _get) => ({
    testRunId: undefined,
    testRunInProgress: false,
    setTestRunId: (testRunId: string | undefined) => set({ testRunId: testRunId }),
    setTestRunInProgress: (testRunInProgress: boolean) =>
      set({ testRunInProgress: testRunInProgress }),
  }))
);
