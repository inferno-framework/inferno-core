export type Message = {
  message: string;
  type: 'error' | 'warning' | 'info';
};

export type ViewType = 'run' | 'report' | 'config';

export type RequestHeader = {
  name: string;
  value: string;
};

export type Request = {
  direction: string;
  id: string;
  index: number;
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
  inputs?: TestInput[];
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

export type Runnable = {
  id: string;
  title: string;
  short_title?: string;
  description?: string | null;
  short_description?: string;
  result?: Result;
  inputs: TestInput[];
  optional?: boolean;
  input_instructions?: string;
  is_running?: boolean;
};

export type Test = Runnable & {
  short_id: string;
  outputs: TestOutput[];
  user_runnable?: boolean;
};

export type TestGroup = Runnable & {
  short_id: string;
  parent_group?: TestGroup | null;
  test_groups: TestGroup[];
  outputs: TestOutput[];
  tests: Test[];
  run_as_group?: boolean;
  user_runnable?: boolean;
  test_count?: number;
  expanded?: boolean;
};

export type TestSuite = Runnable & {
  run_as_group?: boolean;
  test_count?: number;
  test_groups?: TestGroup[];
  configuration_messages?: Message[];
  version?: string;
  presets?: PresetSummary[];
  suite_options?: SuiteOption[];
  links?: FooterLink[];
  suite_summary?: string;
};

export interface TestSession {
  id: string;
  test_suite: TestSuite;
  test_suite_id: string;
  suite_options?: SuiteOption[];
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

export interface PresetSummary {
  id: string;
  title: string;
}

export interface SuiteOption {
  id: string;
  title?: string;
  description?: string;
  list_options?: SuiteOptionChoice[];
  value?: string;
}

export interface SuiteOptionChoice {
  label: string;
  id: string;
  value: string;
}

export type FooterLink = {
  label: string;
  url: string;
};
