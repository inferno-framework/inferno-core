import { create } from 'zustand';
import { persist } from 'zustand/middleware';

import { devtoolsInDev } from './devtools';

interface CurrentRunnables {
  [key: string]: string;
}

type TestSessionStore = {
  readOnly: boolean;
  currentRunnables: CurrentRunnables;
  runnableId: string;
  testRunId: string | undefined;
  setReadOnly: (readOnly: boolean) => void;
  setCurrentRunnables: (currentRunnables: CurrentRunnables) => void;
  setRunnableId: (runnableId: string) => void;
  setTestRunId: (testRunId: string | undefined) => void;
};

export const useTestSessionStore = create<TestSessionStore>()(
  persist(
    devtoolsInDev(
      (set, _get): TestSessionStore => ({
        readOnly: false,
        currentRunnables: {},
        runnableId: '',
        testRunId: undefined,
        setReadOnly: (readOnly: boolean) => set({ readOnly: readOnly }),
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
