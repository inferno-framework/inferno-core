import { describe, expect, it, vi, afterEach } from 'vitest';
import { getCoreVersion } from '~/api/VersionsApi';

afterEach(() => vi.unstubAllGlobals());

describe('getCoreVersion', () => {
  it('returns the version string from the response', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
      json: vi.fn().mockResolvedValue({ version: '1.2.3' }),
    }));

    expect(await getCoreVersion()).toBe('1.2.3');
  });

  it('returns empty string when the response has no version field', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
      json: vi.fn().mockResolvedValue({ other: 'stuff' }),
    }));

    expect(await getCoreVersion()).toBe('');
  });

  it('returns empty string when fetch rejects', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('Network error')));

    expect(await getCoreVersion()).toBe('');
  });
});
