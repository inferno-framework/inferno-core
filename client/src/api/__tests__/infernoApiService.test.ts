import { describe, expect, it } from 'vitest';
import { getApiEndpoint, getStaticPath, getPath } from '~/api/infernoApiService';

// basePath is undefined in jsdom (no <meta id="base-path"> element);
// tests validate structural behavior rather than the basePath prefix itself.

describe('getPath', () => {
  it('appends a non-slash route with a separator', () => {
    const result = getPath('api');
    expect(result.endsWith('/api')).toBe(true);
  });

  it('does not double-slash a slash-prefixed route', () => {
    const result = getPath('/version');
    expect(result.endsWith('/version')).toBe(true);
    expect(result).not.toMatch(/\/\//);
  });
});

describe('getApiEndpoint', () => {
  it('returns an endpoint URL with no query string when parameters are omitted', () => {
    const result = getApiEndpoint('/test_sessions');
    expect(result).toContain('/test_sessions');
    expect(result).not.toContain('?');
  });

  it('appends a single query parameter', () => {
    const result = getApiEndpoint('/test_sessions', [{ name: 'test_suite_id', value: 'demo' }]);
    expect(result).toContain('?test_suite_id=demo');
  });

  it('joins multiple parameters with &', () => {
    const result = getApiEndpoint('/test_sessions', [
      { name: 'a', value: '1' },
      { name: 'b', value: '2' },
    ]);
    expect(result).toContain('a=1&b=2');
  });
});

describe('getStaticPath', () => {
  it('returns the route unchanged when not in production', () => {
    // NODE_ENV is 'test' in vitest, so the non-production branch executes
    expect(getStaticPath('/public/bundle.js')).toBe('/public/bundle.js');
  });
});
