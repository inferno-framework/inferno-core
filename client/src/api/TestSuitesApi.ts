import { TestSuite } from 'models/testSuiteModels';
import { getApiEndpoint } from './infernoApiService';

export function getTestSuites(): Promise<TestSuite[]> {
  let testSets: TestSuite[] = [];
  const testSuitesEndpoint = getApiEndpoint('/test_suites');
  return fetch(testSuitesEndpoint)
    .then((response) => response.json())
    .then((result) => {
      testSets = result as TestSuite[];
      return [testSets[0]] || [];
    })
    .catch(() => {
      return [];
    });
}
