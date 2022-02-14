import { Result, TestGroup, TestOutput, TestRun, TestSession } from 'models/testSuiteModels';
import { getApiEndpoint } from './infernoApiService';

export function getLastTestRun(test_session_id: string): Promise<TestRun | null> {
  const testSessionsEndpoint = getApiEndpoint(
    '/test_sessions/' + test_session_id + '/last_test_run'
  );
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
  const testSessionsEndpoint = getApiEndpoint('/test_sessions/' + test_session_id);
  return fetch(testSessionsEndpoint)
    .then((response) => response.json())
    .then((result) => {
      return assignParentGroups(result as TestSession);
    })
    .catch((e) => {
      console.log(e);
      return null;
    });
}

export function postTestSessions(testSuiteID: string): Promise<TestSession | null> {
  const testSuiteIDParameter = { name: 'test_suite_id', value: testSuiteID };
  const postEndpoint = getApiEndpoint('/test_sessions', [testSuiteIDParameter]);
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

export function getCurrentTestSessionResults(test_session_id: string): Promise<Result[] | null> {
  const endpoint = getApiEndpoint(`/test_sessions/${test_session_id}/results`);
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

export function getTestSessionData(test_session_id: string): Promise<TestOutput[] | null> {
  const endpoint = getApiEndpoint(`/test_sessions/${test_session_id}/session_data`);
  return fetch(endpoint)
    .then((response) => response.json())
    .then((result) => {
      return result as TestOutput[];
    })
    .catch((e) => {
      console.log(e);
      return null;
    });
}

function assignParentGroups(session: TestSession): TestSession {
  let groups = session.test_suite.test_groups;
  if (groups) {
    groups = assignParentGroupsHelper(groups, null);
  }
  return session;
}

function assignParentGroupsHelper(groups: TestGroup[], parent: TestGroup | null): TestGroup[] {
  groups.forEach((group) => {
    if (
      !group.test_groups ||
      group.test_groups.length === 0 ||
      group.test_groups.every((tg) => tg.parent_group)
    ) {
      group.parent_group = parent;
    } else {
      assignParentGroupsHelper(group.test_groups, group);
    }
  });
  return groups;
}
