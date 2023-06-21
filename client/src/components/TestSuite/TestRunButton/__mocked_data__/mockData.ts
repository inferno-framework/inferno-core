import { RunnableType } from '~/models/testSuiteModels';

export const mockedRunTests = (runnableType: RunnableType, runnableId: string) => {
  console.log(runnableType, runnableId);
};

export const mockedTestRunButtonData = {
  mockedTest: {
    id: 'mock-test-id',
    title: 'Mock Test',
    inputs: [],
    short_id: 'test',
    outputs: [],
    user_runnable: true,
  },
  mockedRunTests,
};
