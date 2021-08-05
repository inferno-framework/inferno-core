/* eslint-disable @typescript-eslint/no-unsafe-assignment */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
import {
  TestSuite,
  TestSession,
  RunnableType,
  TestInput,
  TestRun,
  Result,
  Request,
} from 'models/testSuiteModels';

const apiEndpoint = '/api';

type parameter = {
  name: string;
  value: string;
};

function getEndpoint(route: string, parameters?: parameter[]): string {
  if (parameters) {
    const parametersString = parameters
      .map((parameter) => `${parameter.name}=${parameter.value}`)
      .join('&');
    return `${apiEndpoint}${route}?${parametersString}`;
  }
  return apiEndpoint + route;
}

export function getTestSuites(): Promise<TestSuite[]> {
  let testSets: TestSuite[] = [];
  const testSuitesEndpoint = getEndpoint('/test_suites');
  return fetch(testSuitesEndpoint)
    .then((response) => response.json())
    .then((result) => {
      testSets = result as TestSuite[];
      return testSets;
    })
    .catch((e) => {
      console.log(e);
      return [];
    });
}

export function getLastTestRun(test_session_id: string): Promise<TestRun | null> {
  const testSessionsEndpoint = getEndpoint('/test_sessions/' + test_session_id + '/last_test_run');
  return fetch(testSessionsEndpoint)
    .then((response) => response.json())
    .then((result) => {
      return result as TestRun;
    })
    .catch((e) => {
      console.log(e);
      return null;
    });
}

export function getTestSession(test_session_id: string): Promise<TestSession | null> {
  const testSessionsEndpoint = getEndpoint('/test_sessions/' + test_session_id);
  return fetch(testSessionsEndpoint)
    .then((response) => response.json())
    .then((result) => {
      return result as TestSession;
    })
    .catch((e) => {
      console.log(e);
      return null;
    });
}

export function postTestSessions(testSuiteID: string): Promise<TestSession | null> {
  const testSuiteIDParameter = { name: 'test_suite_id', value: testSuiteID };
  const postEndpoint = getEndpoint('/test_sessions', [testSuiteIDParameter]);
  return fetch(postEndpoint, { method: 'POST' })
    .then((response) => response.json())
    .then((result) => {
      console.log(result);
      return result as TestSession;
    })
    .catch((e) => {
      console.log(e);
      return null;
    });
}

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
): Promise<TestRun> {
  const postEndpoint = getEndpoint('/test_runs');
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
    })
    .catch((e) => {
      console.log(e);
      return { id: 'error', testSessionId: testSessionId };
    });
}

export function getTestRunWithResults(
  testRunId: string,
  time: string | null | undefined
): Promise<TestRun | null> {
  let endpoint = getEndpoint(`/test_runs/${testRunId}?include_results=true`);
  if (time) {
    endpoint += `&after=${time}`;
  }
  return fetch(endpoint)
    .then((response) => response.json())
    .then((testRun) => {
      return testRun as TestRun;
    })
    .catch((e) => {
      console.log(e);
      return null;
    });
}

export function getCurrentTestSessionResults(test_session_id: string): Promise<Result[] | null> {
  const endpoint = getEndpoint(`/test_sessions/${test_session_id}/results`);
  return fetch(endpoint)
    .then((response) => response.json())
    .then((result) => {
      return result as Result[];
    })
    .catch((e) => {
      console.log(e);
      return null;
    });
}

export function getRequestDetails(requestId: string): Promise<Request | null> {
  const endpoint = getEndpoint(`/requests/${requestId}`);
  return fetch(endpoint)
    .then((response) => response.json())
    .then((result) => {
      return result as Request;
    })
    .catch((e) => {
      console.log(e);
      return null;
    });
}
