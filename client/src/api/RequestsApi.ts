import { getApiEndpoint } from './infernoApiService';
import { Request } from 'models/testSuiteModels';

export function getRequestDetails(requestId: string): Promise<Request | null> {
  const endpoint = getApiEndpoint(`/requests/${requestId}`);
  return fetch(endpoint)
    .then((response) => response.json())
    .then((result) => {
      return result as Request;
    });
}
