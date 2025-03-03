import { create } from 'zustand';
import { persist } from 'zustand/middleware';

import { devtoolsInDev } from './devtools';

interface CurrentRunnables {
  [key: string]: string;
}

type TestSessionStore = {
  viewOnly: boolean;
  currentRunnables: CurrentRunnables;
  runnableId: string;
  testRunId: string | undefined;
  setViewOnly: (viewOnly: boolean) => void;
  setCurrentRunnables: (currentRunnables: CurrentRunnables) => void;
  setRunnableId: (runnableId: string) => void;
  setTestRunId: (testRunId: string | undefined) => void;
};

export const useTestSessionStore = create<TestSessionStore>()(
  persist(
    devtoolsInDev(
      (set, _get): TestSessionStore => ({
        viewOnly: false,
        currentRunnables: {},
        runnableId: '',
        testRunId: undefined,
        setViewOnly: (viewOnly: boolean) => set({ viewOnly: viewOnly }),
        setCurrentRunnables: (currentRunnables: CurrentRunnables) =>
          set({ currentRunnables: { ...currentRunnables } }),
        setRunnableId: (runnableId: string) => set({ runnableId: runnableId }),
        setTestRunId: (testRunId: string | undefined) => set({ testRunId: testRunId }),
      }),
    ),
    {
      name: 'test-session',
    },
  ),
);
