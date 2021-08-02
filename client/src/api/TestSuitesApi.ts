import { TestSuite } from "models/testSuiteModels";
import { getEndpoint } from "./infernoApiService";

export function getTestSuites(): Promise<TestSuite[]> {
  let testSets: TestSuite[] = [];
  const testSuitesEndpoint = getEndpoint('/test_suites');
  return fetch(testSuitesEndpoint)
    .then((response) => response.json())
    .then((result) => {
      testSets = result as TestSuite[];
      return testSets;
    })
    .catch((e) => {
      console.log(e);
      return [];
    });
}