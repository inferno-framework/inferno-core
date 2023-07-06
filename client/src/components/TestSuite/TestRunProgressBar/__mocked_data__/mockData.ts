import { Result, TestRun } from 'models/testSuiteModels';

const mockedResults: Result[] = [
  {
    created_at: '2021-11-30T15:22:02.317-05:00',
    id: 'e1f0c5c3-1a84-4427-aaea-812cc69109c1',
    outputs: [],
    result: 'pass',
    test_id: 'demo-Group01-DemoIG_STU1::DemoGroup-Test01',
    test_run_id: '5d78776b-604c-474a-adf2-64354930efe7',
    test_session_id: 'b3e47db8-cb7d-423a-8fdb-f8dcdb856a54',
    updated_at: '2021-11-30T15:22:02.317-05:00',
  },
  {
    created_at: '2021-11-30T15:22:02.328-05:00',
    id: '34bd99e6-6c27-4b31-8082-5f4fec881c4d',
    messages: [{ message: '\n# blah\n*boo*\n\n', type: 'warning' }],
    outputs: [],
    result: 'pass',
    test_id: 'demo-Group01-DemoIG_STU1::DemoGroup-Test02',
    test_run_id: '5d78776b-604c-474a-adf2-64354930efe7',
    test_session_id: 'b3e47db8-cb7d-423a-8fdb-f8dcdb856a54',
    updated_at: '2021-11-30T15:22:02.328-05:00',
  },
];

export const mockedTestRun: TestRun = {
  id: 'mock-test-run',
  results: mockedResults,
  status: 'running',
  test_count: mockedResults.length,
  test_group_id: 'test-group-id',
  test_suite_id: 'test-suite-id',
  test_id: 'test-id',
};

export const getMockedResultsMap: () => Map<string, Result> = () => {
  const resultsMap = new Map<string, Result>();
  mockedResults.forEach((result) => {
    resultsMap.set(result.id, result);
  });
  return resultsMap;
};
