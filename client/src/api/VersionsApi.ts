import { getApiEndpoint } from './infernoApiService';

export function getCoreVersion(): Promise<string> {
  const endpoint = getApiEndpoint('/version');
  return fetch(endpoint)
    .then((response) => response.json())
    .then((result) => {
      return 'version' in result ? (result.version as string) : ''; // eslint-disable-line
    })
    .catch((e) => {
      console.error(e);
      return '';
    });
}
