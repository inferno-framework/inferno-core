export type Message = {
  message: string;
  type: string;
};

export type RequestHeader = {
  name: string;
  value: string;
};

export type Request = {
  direction: string;
  id: string;
  status: number;
  timestamp: string;
  url: string;
  verb: string;
  request_headers?: RequestHeader[];
  response_headers?: RequestHeader[];
  request_body?: string;
  response_body?: string;
};

export interface Result {
  id: string;
  result: string;
  test_id?: string;
  test_group_id?: string;
  test_suite_id?: string;
  test_run_id: string;
  test_session_id: string;
  messages?: Message[];
  requests?: Request[];
  result_message?: string;
}

export interface TestInput {
  key: string;
  title?: string;
  description?: string;
  value?: string;
}

export interface TestOutput {
  name: string;
}

export interface Test {
  id: string;
  title: string;
  result?: Result;
  inputs: TestInput[];
  outputs: TestOutput[];
  description?: string;
}

export interface TestGroup {
  id: string;
  title: string;
  test_groups: TestGroup[];
  inputs: TestInput[];
  outputs: TestOutput[];
  result?: Result;
  tests: Test[];
  description?: string;
}

export interface TestSuite {
  title: string;
  id: string;
  result?: Result;
  test_groups?: TestGroup[];
  description?: string;
}

export interface TestSession {
  id: string;
  test_suite: TestSuite;
  test_suite_id: string;
}

export enum RunnableType {
  TestSuite,
  TestGroup,
  Test,
}

export interface TestRun {
  id: string;
  inputs?: TestInput[] | null;
  results?: Result[] | null;
  status?: string | null;
  testGroupId?: string;
  testSuiteId?: string;
  testId?: string;
}
