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
  setCurrentRunnables: (currentRunnables: CurrentRunnables) => void;
  setRunnableId: (runnableId: string) => void;
  setTestRunId: (testRunId: string | undefined) => void;
};

export const useTestSessionStore = create<TestSessionStore>()(
  persist(
    devtoolsInDev(
      (set, _get): TestSessionStore => ({
        currentRunnables: {},
        runnableId: '',
        testRunId: undefined,
        setCurrentRunnables: (currentRunnables: CurrentRunnables) =>
          set({ currentRunnables: { ...currentRunnables } }),
        setRunnableId: (runnableId: string) => set({ runnableId: runnableId }),
        setTestRunId: (testRunId: string | undefined) => set({ testRunId: testRunId }),
      })
    ),
    {
      name: 'test-session',
    }
  )
);
