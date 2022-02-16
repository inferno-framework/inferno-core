export type Message = {
  message: string;
  type: 'error' | 'warning' | 'info';
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
  optional?: boolean;
}

export interface TestInput {
  name: string;
  title?: string;
  value?: unknown;
  type?: 'text' | 'textarea' | 'oauth_credentials' | 'radio';
  description?: string;
  default?: string;
  optional?: boolean;
  locked?: boolean;
  options?: {
    list_options?: InputOption[];
  };
}

export interface InputOption {
  label: string;
  value: string;
}

export interface TestOutput {
  name: string;
  value: string | undefined;
}

export interface Test {
  id: string;
  title: string;
  short_title?: string;
  result?: Result;
  inputs: TestInput[];
  outputs: TestOutput[];
  input_instructions?: string;
  description?: string;
  short_description?: string;
  user_runnable?: boolean;
  optional?: boolean;
}

export interface TestGroup {
  id: string;
  title: string;
  short_title?: string;
  parent_group?: TestGroup | null;
  test_groups: TestGroup[];
  inputs: TestInput[];
  outputs: TestOutput[];
  input_instructions?: string;
  tests: Test[];
  result?: Result;
  description?: string | null;
  short_description?: string;
  run_as_group?: boolean;
  user_runnable?: boolean;
  test_count?: number;
  optional?: boolean;
}

export interface TestSuite {
  title: string;
  short_title?: string;
  id: string;
  description?: string | null;
  short_descripton?: string;
  run_as_group?: boolean;
  result?: Result;
  test_count?: number;
  test_groups?: TestGroup[];
  optional?: boolean;
  input_instructions?: string;
  configuration_messages?: Message[];
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
  status?: 'queued' | 'running' | 'waiting' | 'cancelling' | 'done';
  test_count?: number;
  test_group_id?: string;
  test_suite_id?: string;
  test_id?: string;
}

export interface OAuthCredentials {
  access_token: string;
  refresh_token?: string;
  expires_in?: string;
  client_id?: string;
  client_secret?: string;
  token_url?: string;
}

export function runnableIsTestSuite(runnable: TestSuite | TestGroup | Test): runnable is TestSuite {
  return (runnable as TestGroup).inputs == undefined;
}
