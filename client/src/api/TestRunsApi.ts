import { RunnableType, TestInput, TestRun } from 'models/testSuiteModels';
import { getApiEndpoint } from './infernoApiService';

interface CreateTestRunBody {
  test_session_id: string;
  inputs: TestInput[];
  test_group_id?: string;
  test_suite_id?: string;
  test_id?: string;
}

export function postTestRun(
  testSessionId: string,
  runnableType: RunnableType,
  runnableId: string,
  inputs: TestInput[]
): Promise<TestRun | null> {
  const postEndpoint = getApiEndpoint('/test_runs');
  const postBody: CreateTestRunBody = {
    test_session_id: testSessionId,
    inputs: inputs,
  };
  switch (runnableType) {
    case RunnableType.TestSuite:
      postBody.test_suite_id = runnableId;
      break;
    case RunnableType.TestGroup:
      postBody.test_group_id = runnableId;
      break;
    case RunnableType.Test:
      postBody.test_id = runnableId;
      break;
  }
  return fetch(postEndpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(postBody),
  })
    .then((response) => response.json())
    .then((result) => {
      return result as TestRun;
    });
}

export function deleteTestRun(testRunId: string): Promise<Response> {
  const endpoint = getApiEndpoint(`/test_runs/${testRunId}`);
  return fetch(endpoint, { method: 'DELETE' });
}

export function getTestRunWithResults(
  testRunId: string,
  time: string | null | undefined
): Promise<TestRun | null> {
  let endpoint = getApiEndpoint(`/test_runs/${testRunId}?include_results=true`);
  if (time) {
    endpoint += `&after=${time}`;
  }
  return fetch(endpoint)
    .then((response) => response.json())
    .then((testRun) => {
      return testRun as TestRun;
    });
}
