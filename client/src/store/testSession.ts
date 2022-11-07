import create from 'zustand';
import { persist } from 'zustand/middleware';

import { devtoolsInDev } from './devtools';

type TestSessionStore = {
  testRunId: string | undefined;
  testRunInProgress: boolean;
  setTestRunId: (testRunId: string | undefined) => void;
  setTestRunInProgress: (testRunInProgress: boolean) => void;
};

export const useTestSessionStore = create<TestSessionStore>(
  persist(
    devtoolsInDev(
      (set, _get) =>
        ({
          testRunId: undefined,
          testRunInProgress: false,
          setTestRunId: (testRunId: string | undefined) => set({ testRunId: testRunId }),
          setTestRunInProgress: (testRunInProgress: boolean) =>
            set({ testRunInProgress: testRunInProgress }),
        } as TestSessionStore)
    ),
    {
      name: 'test-session',
    }
  )
);
