import create from 'zustand';
import { persist } from 'zustand/middleware';

import { devtoolsInDev } from './devtools';

type TestSessionStore = {
  runnableId: string;
  testRunId: string | undefined;
  testRunInProgress: boolean;
  setRunnableId: (runnableId: string | undefined) => void;
  setTestRunId: (testRunId: string | undefined) => void;
  setTestRunInProgress: (testRunInProgress: boolean) => void;
};

export const useTestSessionStore = create<TestSessionStore>(
  persist(
    devtoolsInDev(
      (set, _get) =>
        ({
          runnableId: '',
          testRunId: undefined,
          testRunInProgress: false,
          setRunnableId: (runnableId: string) => set({ runnableId: runnableId }),
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
