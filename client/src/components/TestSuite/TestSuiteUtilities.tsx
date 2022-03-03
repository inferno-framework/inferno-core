import { Test, TestGroup, TestSuite } from 'models/testSuiteModels';

export const shouldShowDescription = (
  runnable: Test | TestGroup | TestSuite,
  description: JSX.Element | undefined
): boolean => {
  if (description && runnable.description && runnable.description.length > 0) {
    return true;
  } else {
    return false;
  }
};
