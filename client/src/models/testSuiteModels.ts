import { ReactElement } from 'react';
import { Option } from './selectionModels';

export interface Auth {
  auth_type?: string;
  use_discovery?: boolean;
  token_url?: string;
  auth_url?: string;
  requested_scopes?: string;
  client_id?: string;
  client_secret?: string;
  redirect_url?: string;
  pkce_support?: string;
  pkce_code_challenge_method?: string;
  auth_request_method?: string;
  encryption_algorithm?: string;
  kid?: string;
  jwks?: string;
  access_token?: string;
  refresh_token?: string;
  issue_time?: string;
  expires_in?: string;
}

export interface CheckboxValues {
  [key: string]: boolean;
}

export type FooterLink = {
  label: string;
  url: string;
};

export interface InputOption {
  label: string;
  value: string;
  locked?: boolean;
}

export interface InputValues {
  [key: string]: unknown;
}

export type Message = {
  message: string;
  type: 'error' | 'warning' | 'info';
};

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

export type RequestHeader = {
  name: string;
  value: string;
};

export type Requirement = {
  id: string;
  requirement: string;
  conformance: string;
  actor: string;
  conditionality: string;
  url?: string;
  sub_requirements: string[];
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

export interface SuiteOption extends Option {
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

export interface TestInput {
  name: string;
  title?: string | ReactElement;
  value?: unknown;
  type?: 'auth_info' | 'oauth_credentials' | 'checkbox' | 'radio' | 'select' | 'text' | 'textarea';
  description?: string;
  default?: string | string[];
  optional?: boolean;
  locked?: boolean;
  hidden?: boolean;
  options?: {
    components?: TestInput[];
    list_options?: InputOption[];
    mode?: string;
  };
}

export interface TestOutput {
  name: string;
  value: string | undefined;
}

export interface TestRun {
  id: string;
  inputs?: TestInput[] | null;
  results?: Result[] | null;
  status?: 'queued' | 'running' | 'waiting' | 'cancelling' | 'done';
  test_count?: number;
  test_group_id?: string;
  test_id?: string;
  test_session_id?: string;
  test_suite_id?: string;
}

export interface TestSession {
  id: string;
  test_suite: TestSuite;
  test_suite_id: string;
  suite_options?: SuiteOption[];
}

export type ViewType = 'run' | 'report' | 'requirements' | 'config';

// ==========================================
// RUNNABLES
// ==========================================

export enum RunnableType {
  TestSuite,
  TestGroup,
  Test,
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
  verifies_requirements?: string[];
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

// Custom type guards to determine type of Runnable
export const isTest = (object: Runnable): object is Test => {
  return !('test_groups' in object);
};

export const isTestGroup = (object: Runnable): object is TestGroup => {
  return 'test_groups' in object && 'tests' in object;
};

export const isTestSuite = (object: Runnable): object is TestSuite => {
  return 'test_groups' in object && !('tests' in object);
};
