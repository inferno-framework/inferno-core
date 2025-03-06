import { SuiteOptionChoice } from './testSuiteModels';

export type Option = {
  id: string;
  title?: string;
};

export type ListOption = Option;

export type ListOptionSelection = string;

export type RadioOption = Option & {
  description: string;
  default?: string;
  list_options: SuiteOptionChoice[]; // Make this generic if other options are introduced
};

export type RadioOptionSelection = {
  id: string;
  value: string;
};

export const isListOption = (object: Option): object is ListOption => {
  return 'title' in object && !('list_options' in object);
};

export const isRadioOption = (object: Option): object is RadioOption => {
  return 'title' in object && 'list_options' in object;
};

export const isListOptionSelection = (
  object: ListOptionSelection | RadioOptionSelection[],
): object is ListOptionSelection => {
  return typeof object === 'string';
};

export const isRadioOptionSelection = (
  object: ListOptionSelection | RadioOptionSelection[],
): object is RadioOptionSelection[] => {
  return Array.isArray(object);
};
