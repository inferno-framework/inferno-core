import { getApiEndpoint } from "./infernoApiService";

export function getCoreVersion(): Promise<string> {
  const versionsEndpoint = getApiEndpoint('/version')
  return fetch(versionsEndpoint)
    .then((response) => response.json())
    .then((result) => {
      result as String;
      return result;
    })
    .catch((e) => {
      console.log(e)
      return [];
    });
}