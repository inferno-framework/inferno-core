import { Request } from 'models/testSuiteModels';

export const mockedRequest: Request = {
  direction: 'outgoing',
  id: '20a3709a-eebf-42a7-9035-a58b00c8f104',
  index: 1,
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

export const codeResponseWithHtml: Request = {
  direction: 'outgoing',
  id: 'de793781-5eed-421a-88d3-8029499f4bce',
  index: 2,
  status: 200,
  timestamp: '2022-04-21T22:22:04.039Z',
  url: 'NA',
  verb: 'get',
  result_id: 'b01dce20-72a8-43e5-b99d-34f3843eddee',
  response_headers: [{ name: 'content-type', value: 'text/html; charset=UTF-8' }],
  // eslint-disable-next-line prettier/prettier
  response_body: '<html>html has newlines already</html>',
};

export const codeResponseWithJson: Request = {
  direction: 'outgoing',
  id: 'de793781-5eed-421a-88d3-8029499f4bce',
  index: 3,
  status: 200,
  timestamp: '2022-04-21T22:22:04.039Z',
  url: 'NA',
  verb: 'get',
  result_id: 'b01dce20-72a8-43e5-b99d-34f3843eddee',
  response_headers: [{ name: 'content-type', value: 'application/fhir+json charset=UTF-8' }],
  // eslint-disable-next-line prettier/prettier
  response_body:
    '{"resourceType": "OperationOutcome", "issue": [ {"severity": "error", "code": "processing", "diagnostics": "Bearer token is invalid or not supplied Supplied Bearer Token: null" } ]}',
};

export const mockedUpdateRequest = (requestId: string, resultId: string, request: Request) => {
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const data = [requestId, resultId, request];
};

export const mockedRequestFunctions = {
  updateRequest: mockedUpdateRequest,
};
