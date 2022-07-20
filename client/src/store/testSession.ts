import create from 'zustand';
import { devtoolsInDev } from './devtools';

import { ViewType } from '~/models/testSuiteModels';

type TestSessionStore = {
  view: ViewType | undefined;
  setView: (view: ViewType) => void;
};

export const useTestSessionStore = create<TestSessionStore>(
  devtoolsInDev((set, _get) => ({
    view: undefined,
    setView: (view: ViewType | undefined) => set({ view: view }),
  }))
);
