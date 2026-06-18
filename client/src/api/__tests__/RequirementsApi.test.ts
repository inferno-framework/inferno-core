import { describe, expect, it, vi, afterEach } from 'vitest';
import { getTestSuiteRequirements, getSingleRequirement } from '~/api/RequirementsApi';
import { Requirement } from '~/models/testSuiteModels';

afterEach(() => vi.unstubAllGlobals());

const mockRequirement: Requirement = {
  id: 'req-1',
  requirement: 'SHALL do something',
  conformance: 'SHALL',
  actor: 'Client',
  conditionality: 'false',
  subrequirements: [],
};

describe('getTestSuiteRequirements', () => {
  it('fetches and returns a requirements list', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        json: vi.fn().mockResolvedValue([mockRequirement]),
      }),
    );

    const result = await getTestSuiteRequirements('suite-1', 'session-1');
    expect(result).toEqual([mockRequirement]);
  });

  it('returns an empty array when the response is null', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        json: vi.fn().mockResolvedValue(null),
      }),
    );

    const result = await getTestSuiteRequirements('suite-1', 'session-1');
    expect(result).toEqual([]);
  });

  it('returns an empty array when fetch throws', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('Network error')));

    const result = await getTestSuiteRequirements('suite-1', 'session-1');
    expect(result).toEqual([]);
  });
});

describe('getSingleRequirement', () => {
  it('fetches and returns a single requirement', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        json: vi.fn().mockResolvedValue(mockRequirement),
      }),
    );

    const result = await getSingleRequirement('req-1');
    expect(result).toEqual(mockRequirement);
  });

  it('returns null when the response is null', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        json: vi.fn().mockResolvedValue(null),
      }),
    );

    const result = await getSingleRequirement('req-1');
    expect(result).toBeNull();
  });

  it('returns null when fetch throws', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('Network error')));

    const result = await getSingleRequirement('req-1');
    expect(result).toBeNull();
  });
});
