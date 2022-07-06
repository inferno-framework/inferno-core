import {
  Result,
  TestGroup,
  TestOutput,
  TestRun,
  TestSession,
  SuiteOption,
} from 'models/testSuiteModels';
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
      return addProperties(result as TestSession);
    })
    .catch((e) => {
      console.log(e);
      return null;
    });
}

export function postTestSessions(
  testSuiteID: string,
  presetId: string | null,
  suiteOptions: SuiteOption[] | null
): Promise<TestSession | null> {
  const testSuiteIDParameter = { name: 'test_suite_id', value: testSuiteID };
  const postEndpoint = getApiEndpoint('/test_sessions', [testSuiteIDParameter]);
  const suiteOptionsPost = suiteOptions?.map((option) => {
    return { id: option.id, value: option.value };
  });
  const postBody = {
    preset_id: presetId,
    suite_options: suiteOptionsPost,
  };
  return fetch(postEndpoint, { method: 'POST', body: JSON.stringify(postBody) })
    .then((response) => response.json())
    .then((result) => {
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

export function applyPreset(test_session_id: string, preset_id: string): Promise<null> {
  const endpoint = getApiEndpoint(
    `/test_sessions/${test_session_id}/session_data/apply_preset?preset_id=${preset_id}`
  );

  return fetch(endpoint, { method: 'PUT' }).then((response) => {
    if (response.status === 200) {
      return null;
    }
    // TODO: handle failures
    return null;
  });
}

/* Populate additional properties for API results */
function addProperties(session: TestSession): TestSession {
  let groups = session.test_suite.test_groups;
  if (groups) {
    groups = assignParentGroups(groups, null);
    groups = expandRunAsGroupChildren(groups, false);
  }
  return session;
}

// Can be safely removed
function assignParentGroups(groups: TestGroup[], parent: TestGroup | null): TestGroup[] {
  groups.forEach((group) => {
    if (
      !group.test_groups ||
      group.test_groups.length === 0 ||
      group.test_groups.every((tg) => tg.parent_group)
    ) {
      group.parent_group = parent;
    } else {
      assignParentGroups(group.test_groups, group);
    }
  });
  return groups;
}

function expandRunAsGroupChildren(groups: TestGroup[], expandChildren: boolean): TestGroup[] {
  groups.forEach((group) => {
    group.expanded = expandChildren;
    if (group.test_groups) {
      if (group.run_as_group) {
        expandRunAsGroupChildren(group.test_groups, true);
      } else {
        expandRunAsGroupChildren(group.test_groups, expandChildren);
      }
    }
  });
  return groups;
}
