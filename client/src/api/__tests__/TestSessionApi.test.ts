import { describe, expect, it, vi, afterEach } from 'vitest';
import {
  getLastTestRun,
  getTestSession,
  postTestSessions,
  getCurrentTestSessionResults,
  getTestSessionData,
  applyPreset,
} from '~/api/TestSessionApi';
import { TestGroup, TestSession } from '~/models/testSuiteModels';

afterEach(() => vi.unstubAllGlobals());

function makeFetchMock(returnValue: unknown) {
  return vi.fn().mockResolvedValue({ json: vi.fn().mockResolvedValue(returnValue) });
}

const baseSession: TestSession = {
  id: 'session-1',
  test_suite_id: 'suite-1',
  test_suite: { id: 'suite-1', title: 'Suite', inputs: [], test_groups: [] },
};

describe('getLastTestRun', () => {
  it('fetches and returns the last test run', async () => {
    const mockRun = { id: 'run-1', status: 'done' };
    vi.stubGlobal('fetch', makeFetchMock(mockRun));

    const result = await getLastTestRun('session-1');
    expect(result).toEqual(mockRun);
  });
});

describe('getTestSession', () => {
  it('fetches and returns the session', async () => {
    vi.stubGlobal('fetch', makeFetchMock(baseSession));

    const result = await getTestSession('session-1');
    expect(result?.id).toBe('session-1');
  });

  it('marks all top-level groups as not expanded', async () => {
    const group: TestGroup = {
      id: 'g1',
      title: 'G1',
      short_id: '1',
      inputs: [],
      outputs: [],
      test_groups: [],
      tests: [],
      run_as_group: false,
    };
    const session = {
      ...baseSession,
      test_suite: { ...baseSession.test_suite, test_groups: [group] },
    };
    vi.stubGlobal('fetch', makeFetchMock(session));

    await getTestSession('session-1');
    expect(group.expanded).toBe(false);
  });

  it('expands direct children of a run_as_group parent', async () => {
    const child: TestGroup = {
      id: 'child',
      title: 'Child',
      short_id: 'c',
      inputs: [],
      outputs: [],
      test_groups: [],
      tests: [],
    };
    const parent: TestGroup = {
      id: 'parent',
      title: 'Parent',
      short_id: 'p',
      inputs: [],
      outputs: [],
      run_as_group: true,
      test_groups: [child],
      tests: [],
    };
    const session = {
      ...baseSession,
      test_suite: { ...baseSession.test_suite, test_groups: [parent] },
    };
    vi.stubGlobal('fetch', makeFetchMock(session));

    await getTestSession('session-1');
    expect(parent.expanded).toBe(false);
    expect(child.expanded).toBe(true);
  });

  it('does not expand children of a non-run_as_group parent', async () => {
    const child: TestGroup = {
      id: 'child',
      title: 'Child',
      short_id: 'c',
      inputs: [],
      outputs: [],
      test_groups: [],
      tests: [],
    };
    const parent: TestGroup = {
      id: 'parent',
      title: 'Parent',
      short_id: 'p',
      inputs: [],
      outputs: [],
      run_as_group: false,
      test_groups: [child],
      tests: [],
    };
    const session = {
      ...baseSession,
      test_suite: { ...baseSession.test_suite, test_groups: [parent] },
    };
    vi.stubGlobal('fetch', makeFetchMock(session));

    await getTestSession('session-1');
    expect(child.expanded).toBe(false);
  });

  it('propagates expansion recursively: grandchild of run_as_group is also expanded', async () => {
    const grandchild: TestGroup = {
      id: 'gc',
      title: 'GC',
      short_id: 'gc',
      inputs: [],
      outputs: [],
      test_groups: [],
      tests: [],
    };
    const child: TestGroup = {
      id: 'child',
      title: 'Child',
      short_id: 'c',
      inputs: [],
      outputs: [],
      test_groups: [grandchild],
      tests: [],
    };
    const parent: TestGroup = {
      id: 'parent',
      title: 'Parent',
      short_id: 'p',
      inputs: [],
      outputs: [],
      run_as_group: true,
      test_groups: [child],
      tests: [],
    };
    const session = {
      ...baseSession,
      test_suite: { ...baseSession.test_suite, test_groups: [parent] },
    };
    vi.stubGlobal('fetch', makeFetchMock(session));

    await getTestSession('session-1');
    expect(child.expanded).toBe(true);
    expect(grandchild.expanded).toBe(true);
  });
});

describe('postTestSessions', () => {
  it('sends the test_suite_id as a query parameter', async () => {
    const fetchMock = makeFetchMock(baseSession);
    vi.stubGlobal('fetch', fetchMock);

    await postTestSessions('suite-1', null, null);

    expect(String(fetchMock.mock.calls[0][0])).toContain('test_suite_id=suite-1');
  });

  it('includes preset_id and mapped suite_options in the body', async () => {
    const fetchMock = makeFetchMock(baseSession);
    vi.stubGlobal('fetch', fetchMock);
    const suiteOptions = [{ id: 'opt-1', value: 'val-1', title: 'Option' }];

    await postTestSessions('suite-1', 'preset-1', suiteOptions);

    const init = fetchMock.mock.calls[0][1] as RequestInit;
    const body = JSON.parse(init.body as string) as Record<string, unknown>;
    expect(body['preset_id']).toBe('preset-1');
    expect(body['suite_options']).toEqual([{ id: 'opt-1', value: 'val-1' }]);
  });

  it('sends undefined suite_options when null is passed', async () => {
    const fetchMock = makeFetchMock(baseSession);
    vi.stubGlobal('fetch', fetchMock);

    await postTestSessions('suite-1', null, null);

    const init = fetchMock.mock.calls[0][1] as RequestInit;
    const body = JSON.parse(init.body as string) as Record<string, unknown>;
    expect(body['suite_options']).toBeUndefined();
    expect(body['preset_id']).toBeNull();
  });
});

describe('getCurrentTestSessionResults', () => {
  it('fetches and returns the results array', async () => {
    const mockResults = [{ id: 'r1', result: 'pass' }];
    vi.stubGlobal('fetch', makeFetchMock(mockResults));

    const result = await getCurrentTestSessionResults('session-1');
    expect(result).toEqual(mockResults);
  });
});

describe('getTestSessionData', () => {
  it('fetches and returns the session data array', async () => {
    const mockData = [{ name: 'token', value: 'abc' }];
    vi.stubGlobal('fetch', makeFetchMock(mockData));

    const result = await getTestSessionData('session-1');
    expect(result).toEqual(mockData);
  });
});

describe('applyPreset', () => {
  it('sends a PUT request with preset_id in the URL', async () => {
    const fetchMock = vi.fn().mockResolvedValue({ status: 200 });
    vi.stubGlobal('fetch', fetchMock);

    await applyPreset('session-1', 'preset-1');

    const [url, init] = fetchMock.mock.calls[0] as [string, RequestInit];
    expect(String(url)).toContain('preset_id=preset-1');
    expect(init.method).toBe('PUT');
  });

  it('returns null on a 200 response', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ status: 200 }));

    const result = await applyPreset('session-1', 'preset-1');
    expect(result).toBeNull();
  });

  it('returns null on a non-200 response', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ status: 422 }));

    const result = await applyPreset('session-1', 'preset-1');
    expect(result).toBeNull();
  });
});
