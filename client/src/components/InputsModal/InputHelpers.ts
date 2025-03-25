import YAML from 'js-yaml';
import { enqueueSnackbar } from 'notistack';
import { Auth, OAuthCredentials, TestInput } from '~/models/testSuiteModels';
import { AuthType, getAuthFields, getAccessFields } from './Auth/AuthSettings';

export const getMissingRequiredInput = (inputs: TestInput[], inputsMap: Map<string, unknown>) => {
  return inputs.some((input: TestInput) => {
    // Radio inputs will always be required and have a default value
    if (input.type === 'radio') return false;

    const inputValue = inputsMap.get(input.name);

    // If required, checkbox inputs must have at least one checked value
    if (input.type === 'checkbox') {
      try {
        let checkboxValues: string[] = [];
        // Sometimes this value is an array instead of a JSON string; if so, then set it directly
        if (Array.isArray(inputValue) && inputValue.every((item) => typeof item === 'string')) {
          checkboxValues = inputValue;
        } else {
          checkboxValues = JSON.parse(inputValue as string) as string[];
        }
        return (
          !input.optional && (Array.isArray(checkboxValues) ? checkboxValues.length === 0 : true)
        );
      } catch (e: unknown) {
        const errorMessage = e instanceof Error ? e.message : String(e);
        enqueueSnackbar(`Checkbox input incorrectly formatted: ${errorMessage}`, {
          variant: 'error',
        });
        return true;
      }
    }

    // If input is auth_info, check if required values are filled
    let authMissingRequiredInput = false;
    if (input.type === 'auth_info') {
      try {
        if (!inputValue || !input.options?.components || input.options?.components.length < 1)
          return false;
        const authJson = JSON.parse(inputValue as string) as Auth;
        const authType = (authJson.auth_type ||
          input.options.components.find((c) => c.name === 'auth_type')?.default) as AuthType;

        // Determine which fields are required; the `authValues` and `components` props
        // in getAuthFields() and getAccessFields() are irrelevant for this
        const fields =
          input.options?.mode === 'auth'
            ? getAuthFields(authType, new Map(), [], false, false)
            : getAccessFields(authType, new Map(), [], false, false);
        const requiredFields = fields.filter((field) => !field.optional).map((field) => field.name);
        authMissingRequiredInput = requiredFields.some((field) => !authJson[field as keyof Auth]);
      } catch (e: unknown) {
        const errorMessage = e instanceof Error ? e.message : String(e);
        enqueueSnackbar(`Auth info inputs incorrectly formatted: ${errorMessage}`, {
          variant: 'error',
        });
        return true;
      }
    }

    // If input has OAuth, check if required values are filled
    let oAuthMissingRequiredInput = false;
    if (input.type === 'oauth_credentials') {
      try {
        const oAuthJson = JSON.parse(
          (inputValue as string) || '{ "access_token": null }',
        ) as OAuthCredentials;
        const accessTokenIsEmpty = !oAuthJson.access_token;
        const refreshTokenIsEmpty =
          !!oAuthJson.refresh_token && (!oAuthJson.token_url || !oAuthJson.client_id);
        oAuthMissingRequiredInput = (!input.optional && accessTokenIsEmpty) || refreshTokenIsEmpty;
      } catch (e: unknown) {
        const errorMessage = e instanceof Error ? e.message : String(e);
        enqueueSnackbar(`OAuth credentials incorrectly formatted: ${errorMessage}`, {
          variant: 'error',
        });
        return true;
      }
    }

    return (
      (!input.optional && !inputValue) || oAuthMissingRequiredInput || authMissingRequiredInput
    );
  });
};

export const parseSerialChanges = (
  inputType: string,
  changes: string,
  setInvalidInput: (isInvalidInput: boolean) => void,
): TestInput[] | undefined => {
  let parsed: TestInput[];
  try {
    parsed = (inputType === 'JSON' ? JSON.parse(changes) : YAML.load(changes)) as TestInput[];
    // Convert OAuth/Auth input values to strings; parsed needs to be an array
    parsed.forEach((input) => {
      if (input.type === 'oauth_credentials' || input.type === 'auth_info') {
        input.value = JSON.stringify(input.value);
      }
    });
    setInvalidInput(false);
    return parsed;
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
  } catch (e) {
    // Ignore errors; assume user error
    setInvalidInput(true);
    return undefined;
  }
};

export const serializeMap = (
  inputType: string,
  inputs: TestInput[],
  map: Map<string, unknown>,
): string => {
  const flatObj = inputs.map((requirement: TestInput) => {
    // Parse out \n chars from descriptions
    const parsedDescription = requirement.description?.replaceAll('\n', ' ').trim();
    if (requirement.type === 'oauth_credentials') {
      return {
        ...requirement,
        description: parsedDescription,
        value: JSON.parse(
          (map.get(requirement.name) as string) || '{ "access_token": "" }',
        ) as OAuthCredentials,
      };
    } else if (requirement.type === 'auth_info') {
      return {
        ...requirement,
        default: JSON.parse((requirement.default as string) || '{}') as Auth,
        description: parsedDescription,
        value: JSON.parse((map.get(requirement.name) as string) || '{}') as Auth,
      };
    } else if (requirement.type === 'radio') {
      const firstVal =
        requirement.options?.list_options && requirement.options?.list_options?.length > 0
          ? requirement.options?.list_options[0]?.value
          : '';
      return {
        ...requirement,
        description: parsedDescription,
        value: map.get(requirement.name) || requirement.default || firstVal,
      };
    } else {
      return {
        ...requirement,
        description: parsedDescription,
        value: map.get(requirement.name) || '',
      };
    }
  });
  return inputType === 'JSON'
    ? JSON.stringify(flatObj, null, 2)
    : YAML.dump(flatObj, { lineWidth: -1 });
};

// Check if string str is JSON object, exempting other types
export const isJsonString = (str: unknown) => {
  if (typeof str !== 'string') return false;
  let value: unknown = str;
  try {
    value = JSON.parse(str);
  } catch {
    return false;
  }
  return !!value && typeof value === 'object';
};
