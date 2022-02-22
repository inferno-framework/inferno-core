import { getApiEndpoint } from './infernoApiService';

export function getCoreVersion(): Promise<string> {
  let version = '';
  const endpoint = getApiEndpoint('/version');
  return fetch(endpoint)
    .then((response) => response.json())
    .then((result) => {
      version = result.version as string;
      return version;
      // return 'version' in result ? (result.version as string) : '';
    })
    .catch((e) => {
      console.log(e);
      return '';
    });
}
