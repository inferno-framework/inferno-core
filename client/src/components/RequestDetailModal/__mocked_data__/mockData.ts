import { Request } from 'models/testSuiteModels';

export const mockedRequest: Request = {
  direction: 'outgoing',
  id: '20a3709a-eebf-42a7-9035-a58b00c8f104',
  request_body: null,
  request_headers: [
    { name: 'user-agent', value: 'Ruby FHIR Client' },
    { name: 'accept-charset', value: 'utf-8' },
    { name: 'accept', value: 'application/fhir+json' },
  ],
  response_body:
    '{\n  "resourceType": "OperationOutcome",\n  "issue": [ {\n    "severity": "error",\n    "code": "processing",\n    "diagnostics": "Bearer token is invalid or not supplied Supplied Bearer Token: null"\n  } ]\n}',
  response_headers: [
    { name: 'server', value: 'nginx/1.21.4' },
    { name: 'date', value: 'Tue, 30 Nov 2021 20:33:46 GMT' },
    { name: 'content-type', value: 'application/fhir+json;charset=utf-8' },
    { name: 'connection', value: 'close' },
    { name: 'x-powered-by', value: 'HAPI FHIR 5.3.0 REST Server (FHIR Server; FHIR 4.0.1/R4)' },
    { name: 'x-request-id', value: '3SK0IVe8US7OQSUk' },
  ],
  result_id: '4e333fb0-548b-4b7e-be5f-9544e5709069',
  status: 401,
  timestamp: '2021-11-30T15:33:46.592-05:00',
  url: 'https://inferno.healthit.gov/reference-server/r4/Patient/85',
  verb: 'get',
};
