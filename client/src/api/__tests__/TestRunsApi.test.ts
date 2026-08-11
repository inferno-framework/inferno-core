import { describe, expect, it, vi, afterEach } from 'vitest';
import { postTestRun, deleteTestRun, getTestRunWithResults } from '~/api/TestRunsApi';
import { RunnableType, TestRun } from '~/models/testSuiteModels';

const mockTestRun: TestRun = { id: 'run-1', test_session_id: 'session-1', status: 'queued' };

function makeFetchMock(returnValue: unknown) {
  return vi.fn().mockResolvedValue({ json: vi.fn().mockResolvedValue(returnValue) });
}

afterEach(() => vi.unstubAllGlobals());

describe('postTestRun', () => {
  it('sends test_suite_id for TestSuite runnable type', async () => {
    const fetchMock = makeFetchMock(mockTestRun);
    vi.stubGlobal('fetch', fetchMock);

    await postTestRun('session-1', RunnableType.TestSuite, 'suite-1', []);

    const init = fetchMock.mock.calls[0][1] as RequestInit;
    const body = JSON.parse(init.body as string) as Record<string, unknown>;
    expect(body['test_suite_id']).toBe('suite-1');
    expect(body).not.toHaveProperty('test_group_id');
    expect(body).not.toHaveProperty('test_id');
  });

  it('sends test_group_id for TestGroup runnable type', async () => {
    const fetchMock = makeFetchMock(mockTestRun);
    vi.stubGlobal('fetch', fetchMock);

    await postTestRun('session-1', RunnableType.TestGroup, 'group-1', []);

    const init = fetchMock.mock.calls[0][1] as RequestInit;
    const body = JSON.parse(init.body as string) as Record<string, unknown>;
    expect(body['test_group_id']).toBe('group-1');
    expect(body).not.toHaveProperty('test_suite_id');
    expect(body).not.toHaveProperty('test_id');
  });

  it('sends test_id for Test runnable type', async () => {
    const fetchMock = makeFetchMock(mockTestRun);
    vi.stubGlobal('fetch', fetchMock);

    await postTestRun('session-1', RunnableType.Test, 'test-1', []);

    const init = fetchMock.mock.calls[0][1] as RequestInit;
    const body = JSON.parse(init.body as string) as Record<string, unknown>;
    expect(body['test_id']).toBe('test-1');
    expect(body).not.toHaveProperty('test_group_id');
    expect(body).not.toHaveProperty('test_suite_id');
  });

  it('includes test_session_id and inputs in the body', async () => {
    const fetchMock = makeFetchMock(mockTestRun);
    vi.stubGlobal('fetch', fetchMock);
    const inputs = [{ name: 'token', value: 'abc' }];

    await postTestRun('session-1', RunnableType.TestSuite, 'suite-1', inputs);

    const init = fetchMock.mock.calls[0][1] as RequestInit;
    const body = JSON.parse(init.body as string) as Record<string, unknown>;
    expect(body['test_session_id']).toBe('session-1');
    expect(body['inputs']).toEqual(inputs);
  });

  it('uses POST method with application/json content-type', async () => {
    const fetchMock = makeFetchMock(mockTestRun);
    vi.stubGlobal('fetch', fetchMock);

    await postTestRun('session-1', RunnableType.TestSuite, 'suite-1', []);

    const init = fetchMock.mock.calls[0][1] as RequestInit;
    expect(init.method).toBe('POST');
    expect((init.headers as Record<string, string>)['Content-Type']).toBe('application/json');
  });

  it('returns the parsed TestRun', async () => {
    vi.stubGlobal('fetch', makeFetchMock(mockTestRun));

    const result = await postTestRun('session-1', RunnableType.TestSuite, 'suite-1', []);
    expect(result).toEqual(mockTestRun);
  });
});

describe('deleteTestRun', () => {
  it('sends a DELETE request to an endpoint containing the run id', async () => {
    const fetchMock = vi.fn().mockResolvedValue({ status: 204 });
    vi.stubGlobal('fetch', fetchMock);

    await deleteTestRun('run-1');

    const [url, init] = fetchMock.mock.calls[0] as [string, RequestInit];
    expect(String(url)).toContain('run-1');
    expect(init.method).toBe('DELETE');
  });
});

describe('getTestRunWithResults', () => {
  it('returns the fetched test run', async () => {
    vi.stubGlobal('fetch', makeFetchMock(mockTestRun));

    const result = await getTestRunWithResults('run-1', null);
    expect(result).toEqual(mockTestRun);
  });

  it('appends an after param when time is provided', async () => {
    const fetchMock = makeFetchMock(mockTestRun);
    vi.stubGlobal('fetch', fetchMock);

    await getTestRunWithResults('run-1', '2024-01-01T00:00:00Z');

    expect(String(fetchMock.mock.calls[0][0])).toContain('after=2024-01-01T00:00:00Z');
  });

  it('does not append an after param when time is null', async () => {
    const fetchMock = makeFetchMock(mockTestRun);
    vi.stubGlobal('fetch', fetchMock);

    await getTestRunWithResults('run-1', null);

    expect(String(fetchMock.mock.calls[0][0])).not.toContain('after=');
  });

  it('does not append an after param when time is undefined', async () => {
    const fetchMock = makeFetchMock(mockTestRun);
    vi.stubGlobal('fetch', fetchMock);

    await getTestRunWithResults('run-1', undefined);

    expect(String(fetchMock.mock.calls[0][0])).not.toContain('after=');
  });
});
