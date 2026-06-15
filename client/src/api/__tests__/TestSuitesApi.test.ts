import { describe, expect, it, vi, afterEach } from 'vitest';
import { getTestSuites } from '~/api/TestSuitesApi';

afterEach(() => vi.unstubAllGlobals());

describe('getTestSuites', () => {
  it('fetches and returns a list of test suites', async () => {
    const mockSuites = [{ id: 'suite-1', title: 'Suite One', inputs: [] }];
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
      json: vi.fn().mockResolvedValue(mockSuites),
    }));

    const result = await getTestSuites();
    expect(result).toEqual(mockSuites);
  });

  it('returns an empty array when the response is null', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
      json: vi.fn().mockResolvedValue(null),
    }));

    const result = await getTestSuites();
    expect(result).toEqual([]);
  });

  it('returns an empty array when fetch rejects', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('Network error')));

    const result = await getTestSuites();
    expect(result).toEqual([]);
  });
});
