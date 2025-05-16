import { Requirement } from 'models/testSuiteModels';
import { getApiEndpoint } from './infernoApiService';

export async function getTestSuiteRequirements(testSuiteId: string): Promise<Requirement[]> {
  const testSuiteRequirementsEndpoint = getApiEndpoint(`/test_suites/${testSuiteId}/requirements`);
  try {
    const response = await fetch(testSuiteRequirementsEndpoint);
    const requirements = (await response.json()) as Requirement[];
    return requirements || [];
  } catch {
    return [];
  }
}

export async function getSingleRequirement(requirementId: string): Promise<Requirement | null> {
  const singleRequirementEndpoint = getApiEndpoint(`/requirements/${requirementId}`);
  try {
    const response = await fetch(singleRequirementEndpoint);
    const requirement = (await response.json()) as Requirement;
    return requirement || null;
  } catch {
    return null;
  }
}
