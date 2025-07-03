import { TestSuite, TestSession } from 'models/testSuiteModels';

export const testSuites: TestSuite[] = [
  {
    id: 'one',
    title: 'Suite One',
    description: '',
    optional: false,
    inputs: [],
  },
  {
    id: 'two',
    title: 'Suite Two',
    description: '',
    optional: false,
    inputs: [],
  },
];

export const singleTestSuite: TestSuite[] = [
  {
    id: 'one',
    title: 'Suite One',
    description: '',
    optional: false,
    inputs: [],
  },
];

export const testSession: TestSession = {
  id: '42',
  test_suite: singleTestSuite[0],
  test_suite_id: 'test-suite-id',
};

export const requirements = [
  {
    id: 'sample-criteria-proposal@1',
    actor: 'Client',
    conditionality: 'false',
    conformance: 'SHALL',
    requirement: 'Feugiat in ante metus dictum. Dignissim cras tincidunt lobortis feugiat.',
    subrequirements: [
      'sample-criteria-proposal@2',
      'sample-criteria-proposal@3',
      'sample-criteria-proposal@4',
      'sample-criteria-proposal@6',
    ],
    url: 'https://hl7.org/fhir/R4/',
  },
  {
    id: 'sample-criteria-proposal@2',
    actor: 'Client',
    conditionality: 'false',
    conformance: 'SHALL',
    requirement: 'tempor incididunt ut labore et dolore magna aliqua',
    subrequirements: ['sample-criteria-proposal@3'],
    url: 'https://hl7.org/fhir/R4/',
  },
];
