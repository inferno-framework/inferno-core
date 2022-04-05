import { Runnable } from 'models/testSuiteModels';

export const shouldShowDescription = (
  runnable: Runnable,
  description: JSX.Element | undefined
): boolean => {
  if (description && runnable.description && runnable.description.length > 0) {
    return true;
  } else {
    return false;
  }
};
