import { getEndpoint } from "./infernoApiService";

export function getRequestDetails(requestId: string): Promise<Request | null> {
  const endpoint = getEndpoint(`/requests/${requestId}`);
  return fetch(endpoint)
    .then((response) => response.json())
    .then((result) => {
      return result as Request;
    })
    .catch((e) => {
      console.log(e);
      return null;
    });
}
