import { create } from 'zustand';
import { persist } from 'zustand/middleware';

import { devtoolsInDev } from './devtools';

interface CurrentRunnables {
  [key: string]: string;
}

type TestSessionStore = {
  currentRunnables: CurrentRunnables;
  runnableId: string;
  testRunId: string | undefined;
  testRunInProgress: boolean;
  setCurrentRunnables: (currentRunnables: CurrentRunnables) => void;
  setRunnableId: (runnableId: string) => void;
  setTestRunId: (testRunId: string | undefined) => void;
  setTestRunInProgress: (testRunInProgress: boolean) => void;
};

export const useTestSessionStore = create<TestSessionStore>()(
  persist(
    devtoolsInDev(
      (set, _get): TestSessionStore => ({
        currentRunnables: {},
        runnableId: '',
        testRunId: undefined,
        testRunInProgress: false,
        setCurrentRunnables: (currentRunnables: CurrentRunnables) =>
          set({ currentRunnables: currentRunnables }),
        setRunnableId: (runnableId: string) => set({ runnableId: runnableId }),
        setTestRunId: (testRunId: string | undefined) => set({ testRunId: testRunId }),
        setTestRunInProgress: (testRunInProgress: boolean) =>
          set({ testRunInProgress: testRunInProgress }),
      })
      // {
      // merge: (persistedState, currentState) =>
      //   // deepMerge(currentState, persistedState),
      // }
    ),
    {
      name: 'test-session',
    }
  )
);
