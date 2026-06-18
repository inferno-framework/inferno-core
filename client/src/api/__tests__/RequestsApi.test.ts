import { describe, expect, it, vi, afterEach } from 'vitest';
import { getRequestDetails } from '~/api/RequestsApi';

afterEach(() => vi.unstubAllGlobals());

const mockRequest = {
  id: 'req-1',
  direction: 'outgoing',
  verb: 'GET',
  url: 'https://example.com',
  index: 0,
  status: 200,
  timestamp: '2024-01-01T00:00:00Z',
  result_id: 'r1',
};

describe('getRequestDetails', () => {
  it('fetches and returns request details', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        json: vi.fn().mockResolvedValue(mockRequest),
      }),
    );

    const result = await getRequestDetails('req-1');
    expect(result).toEqual(mockRequest);
  });

  it('includes the request id in the endpoint URL', async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      json: vi.fn().mockResolvedValue(mockRequest),
    });
    vi.stubGlobal('fetch', fetchMock);

    await getRequestDetails('req-abc-123');

    expect(String(fetchMock.mock.calls[0][0])).toContain('req-abc-123');
  });
});
