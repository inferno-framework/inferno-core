import { TestSession, Result } from 'models/testSuiteModels';

export const mockedTestSession: TestSession = {
  id: 'b3e47db8-cb7d-423a-8fdb-f8dcdb856a54',
  test_suite: {
    description: null,
    id: 'demo',
    test_count: 75,
    test_groups: [
      {
        description: null,
        id: 'demo-Group01',
        inputs: [],
        outputs: [],
        result: {
          created_at: '2021-11-30T15:22:03.496-05:00',
          id: '48eb204e-80a1-46c1-bcb7-3a46dfa05c55',
          outputs: [],
          result: 'error',
          test_group_id: 'demo-Group01',
          test_run_id: '5d78776b-604c-474a-adf2-64354930efe7',
          test_session_id: 'b3e47db8-cb7d-423a-8fdb-f8dcdb856a54',
          updated_at: '2021-11-30T15:22:03.496-05:00',
        },
        run_as_group: false,
        test_count: 22,
        test_groups: [],
        tests: [],
        title: 'Group 1',
        user_runnable: true,
      },
    ],
    title: 'Demonstration Suite',
  },
  test_suite_id: 'demo',
};

export const mockedResultsList: Result[] = [
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

export const mockedTestRunReturnValue = {
  id: '68554bf0-59a3-45a9-85ae-b70d73c6a387',
  inputs: null,
  results: null,
  status: null,
  test_group_id: 'demo-Group01',
  test_session_id: 'test session id',
};

export const mockedResultsReturnValue = [
  {
    id: '0539a644-023f-4cf1-bcef-3117583411c3',
    result: 'pass',
    test_suite_id: 'testSuite',
    test_run_id: '68554bf0-59a3-45a9-85ae-b70d73c6a387',
    test_session_id: 'test session id',
  },
];
