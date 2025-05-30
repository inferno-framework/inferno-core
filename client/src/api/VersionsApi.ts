import { getApiEndpoint } from './infernoApiService';

export function getCoreVersion(): Promise<string> {
  const endpoint = getApiEndpoint('/version');
  return fetch(endpoint)
    .then((response) => response.json())
    .then((result) => {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
      return 'version' in result ? (result.version as string) : '';
    })
    .catch(() => {
      return '';
    });
}
