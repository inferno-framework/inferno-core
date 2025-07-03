import { Test, TestGroup, TestInput, TestSuite } from 'models/testSuiteModels';

export const mockedTest: Test = {
  id: 'mock-test-id',
  title: 'Mock Test',
  inputs: [],
  short_id: 'test',
  outputs: [],
  user_runnable: true,
};

export const mockedUnrunnableTest: Test = {
  id: 'mock-unrunnable-test-id',
  title: 'Mock Unrunnable Test',
  inputs: [],
  short_id: 'unrunnable-test',
  outputs: [],
  user_runnable: false,
};

export const mockedTestGroup: TestGroup = {
  id: 'mock-test-group-id',
  title: 'Mock Test Group',
  inputs: [],
  short_id: 'test-group',
  test_groups: [],
  outputs: [],
  tests: [mockedTest],
};

export const mockedTestSuite: TestSuite = {
  id: 'mock-test-suite-id',
  title: 'Mock Test Suite',
  inputs: [],
  test_groups: [mockedTestGroup],
};

export const mockedAuthInput = {
  name: 'mock_auth_input',
  type: 'auth_info' as TestInput['type'],
  optional: true,
  options: {
    mode: 'auth',
    components: [
      {
        default: 'backend_services',
        name: 'auth_type',
      },
    ],
  },
};

export const mockedSymmetricAuthInput = {
  name: 'mock_auth_input',
  type: 'auth_info' as TestInput['type'],
  optional: true,
  options: {
    mode: 'auth',
    components: [
      {
        default: 'symmetric',
        name: 'auth_type',
      },
    ],
  },
};

export const mockedRequiredFilledAuthInput: TestInput = {
  name: 'mock_auth_input',
  type: 'auth_info' as TestInput['type'],
  options: {
    mode: 'auth',
    components: [
      {
        name: 'auth_type',
        default: 'backend_services',
      },
    ],
  },
  default:
    '{"client_id":"SAMPLE_CONFIDENTIAL_CLIENT_ID","requested_scopes":"launch/patient openid fhirUser patient/*.*"}',
};

export const mockedFullyFilledAuthInput: TestInput = {
  name: 'mock_auth_input',
  type: 'auth_info' as TestInput['type'],
  options: {
    mode: 'auth',
    components: [
      {
        name: 'auth_type',
        default: 'backend_services',
      },
    ],
  },
  default:
    '{"client_id":"SAMPLE_CONFIDENTIAL_CLIENT_ID","requested_scopes":"launch/patient openid fhirUser patient/*.*","encryption_algorithm":"ES384","jwks":"{\\"keys\\":[{\\"kty\\":\\"EC\\",\\"crv\\":\\"P-384\\",\\"x\\":\\"JQKTsV6PT5Szf4QtDA1qrs0EJ1pbimQmM2SKvzOlIAqlph3h1OHmZ2i7MXahIF2C\\",\\"y\\":\\"bRWWQRJBgDa6CTgwofYrHjVGcO-A7WNEnu4oJA5OUJPPPpczgx1g2NsfinK-D2Rw\\",\\"use\\":\\"sig\\",\\"key_ops\\":[\\"verify\\"],\\"ext\\":true,\\"kid\\":\\"4b49a739d1eb115b3225f4cf9beb6d1b\\",\\"alg\\":\\"ES384\\"},{\\"kty\\":\\"EC\\",\\"crv\\":\\"P-384\\",\\"d\\":\\"kDkn55p7gryKk2tj6z2ij7ExUnhi0ngxXosvqa73y7epwgthFqaJwApmiXXU2yhK\\",\\"x\\":\\"JQKTsV6PT5Szf4QtDA1qrs0EJ1pbimQmM2SKvzOlIAqlph3h1OHmZ2i7MXahIF2C\\",\\"y\\":\\"bRWWQRJBgDa6CTgwofYrHjVGcO-A7WNEnu4oJA5OUJPPPpczgx1g2NsfinK-D2Rw\\",\\"key_ops\\":[\\"sign\\"],\\"ext\\":true,\\"kid\\":\\"4b49a739d1eb115b3225f4cf9beb6d1b\\",\\"alg\\":\\"ES384\\"}]}","kid":"4b49a739d1eb115b3225f4cf9beb6d1b"}',
  value:
    '{"requested_scopes":"launch/patient openid fhirUser patient/*.*","client_id":"SAMPLE_CONFIDENTIAL_CLIENT_ID","encryption_algorithm":"ES384","kid":"4b49a739d1eb115b3225f4cf9beb6d1b","jwks":"{\\"keys\\":[{\\"kty\\":\\"EC\\",\\"crv\\":\\"P-384\\",\\"x\\":\\"JQKTsV6PT5Szf4QtDA1qrs0EJ1pbimQmM2SKvzOlIAqlph3h1OHmZ2i7MXahIF2C\\",\\"y\\":\\"bRWWQRJBgDa6CTgwofYrHjVGcO-A7WNEnu4oJA5OUJPPPpczgx1g2NsfinK-D2Rw\\",\\"use\\":\\"sig\\",\\"key_ops\\":[\\"verify\\"],\\"ext\\":true,\\"kid\\":\\"4b49a739d1eb115b3225f4cf9beb6d1b\\",\\"alg\\":\\"ES384\\"},{\\"kty\\":\\"EC\\",\\"crv\\":\\"P-384\\",\\"d\\":\\"kDkn55p7gryKk2tj6z2ij7ExUnhi0ngxXosvqa73y7epwgthFqaJwApmiXXU2yhK\\",\\"x\\":\\"JQKTsV6PT5Szf4QtDA1qrs0EJ1pbimQmM2SKvzOlIAqlph3h1OHmZ2i7MXahIF2C\\",\\"y\\":\\"bRWWQRJBgDa6CTgwofYrHjVGcO-A7WNEnu4oJA5OUJPPPpczgx1g2NsfinK-D2Rw\\",\\"key_ops\\":[\\"sign\\"],\\"ext\\":true,\\"kid\\":\\"4b49a739d1eb115b3225f4cf9beb6d1b\\",\\"alg\\":\\"ES384\\"}]}"}',
};

export const mockedAccessInput = {
  name: 'mock_access_input',
  type: 'auth_info' as TestInput['type'],
  optional: true,
  options: {
    mode: 'access',
    components: [
      {
        name: 'auth_type',
      },
    ],
  },
};
