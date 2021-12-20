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
  request_body?: string | null;
  response_body?: string | null;
  result_id: string;
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
  created_at?: string;
  updated_at: string;
  outputs: TestOutput[];
}

export interface TestInput {
  name: string;
  title?: string;
  value?: string;
  type?: 'text' | 'textarea' | 'radio';
  description?: string;
  default?: string;
  optional?: boolean;
  locked?: boolean;
  inputOptions?: InputOption[];
}

export interface InputOption {
  id: string;
  label: string;
  value: string | number | boolean;
}

export interface TestOutput {
  name: string;
  value: string | undefined;
}

export interface Test {
  id: string;
  title: string;
  result?: Result;
  inputs: TestInput[];
  outputs: TestOutput[];
  description?: string;
  user_runnable?: boolean;
}

export interface TestGroup {
  id: string;
  title: string;
  test_groups: TestGroup[];
  inputs: TestInput[];
  outputs: TestOutput[];
  tests: Test[];
  result?: Result;
  description?: string | null;
  run_as_group?: boolean;
  user_runnable?: boolean;
  test_count?: number;
}

export interface TestSuite {
  title: string;
  id: string;
  description?: string | null;
  result?: Result;
  test_count?: number;
  test_groups?: TestGroup[];
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
  status?: 'queued' | 'running' | 'waiting' | 'done';
  test_count?: number;
  test_group_id?: string;
  test_suite_id?: string;
  test_id?: string;
}

export function runnableIsTestSuite(runnable: TestSuite | TestGroup | Test): runnable is TestSuite {
  return (runnable as TestGroup).inputs == undefined;
}
