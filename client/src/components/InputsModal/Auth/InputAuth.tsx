import React, { FC, useEffect } from 'react';
import { Card, CardContent, InputLabel, List, ListItem } from '@mui/material';
import Markdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { Auth, TestInput } from '~/models/testSuiteModels';
import {
  AuthType,
  getAccessFields,
  getAuthFields,
} from '~/components/InputsModal/Auth/AuthSettings';
import AuthTypeSelector from '~/components/InputsModal/Auth/AuthTypeSelector';
import FieldLabel from '~/components/InputsModal/FieldLabel';
import InputFields from '~/components/InputsModal/InputFields';
import { isJsonString } from '~/components/InputsModal/InputHelpers';
import { useTestSessionStore } from '~/store/testSession';
import useStyles from '../styles';

export interface InputAuthProps {
  mode: 'access' | 'auth';
  input: TestInput;
  index: number;
  inputsMap: Map<string, unknown>;
  setInputsMap: (map: Map<string, unknown>, edited?: boolean) => void;
}

const InputAuth: FC<InputAuthProps> = ({ mode, input, index, inputsMap, setInputsMap }) => {
  const { classes } = useStyles();
  const readOnly = useTestSessionStore((state) => state.readOnly);
  // authValues is a version of inputsMap used exclusively in this component
  const [authValues, setAuthValues] = React.useState<Map<string, unknown>>(new Map());
  const [authValuesPopulated, setAuthValuesPopulated] = React.useState<boolean>(false);

  // Default auth type settings
  const authComponent = input.options?.components?.find(
    (component) => component.name === 'auth_type',
  );
  const authTypeStartingValue = parseJson(input.value).auth_type;
  const firstListOption =
    authComponent?.options?.list_options && authComponent?.options?.list_options?.length > 0
      ? authComponent?.options?.list_options[0].value
      : undefined;
  const [authType, setAuthType] = React.useState<string>(
    (authTypeStartingValue || authComponent?.default || firstListOption || 'public') as string,
  );

  // Set fields depending on mode
  const [authFields, setAuthFields] = React.useState<TestInput[]>(getAuthInputFields(mode));

  useEffect(() => {
    // Set defaults on radio buttons
    // This is necessary because radio buttons with no preset defaults will still cause
    // missing input errors
    setAuthFields(
      authFields.map((field) => {
        if (
          field.type === 'radio' &&
          !field.default &&
          !field.value &&
          field.options?.list_options
        ) {
          field.default = field.options?.list_options[0].value;
        }
        return field;
      }),
    );

    const combinedStartingValues = getStartingValues();
    // After parsing JSON, set auth_type if value exists in input.value
    setAuthType(combinedStartingValues.auth_type || authType);

    // Populate authValues on mount
    authValues.set('auth_type', combinedStartingValues.auth_type || authType);
    authFields.forEach((field: TestInput) => {
      authValues.set(field.name, combinedStartingValues[field.name as keyof Auth] || '');
    });
    setAuthValuesPopulated(true);
  }, []);

  // Set internal inputsMap on InputAuth fields change (usually new preset)
  useEffect(() => {
    const inputsMapValues = parseJson(inputsMap.get(input.name));
    const authValuesCopy = new Map(authValues);
    Object.entries(inputsMapValues).forEach(([key, value]) => {
      authValuesCopy.set(key, value);
    });
    setAuthValues(authValuesCopy);
  }, [inputsMap.get(input.name)]);

  useEffect(() => {
    // Recalculate hidden fields
    setAuthFields(getAuthInputFields(mode));
    updateAuthInputsMap(authValues);
  }, [authValues, authValuesPopulated]);

  function parseJson(jsonInput: unknown) {
    return isJsonString(jsonInput) ? (JSON.parse(jsonInput as string) as Auth) : {};
  }

  function getAuthInputFields(mode: string) {
    if (mode === 'access') {
      return getAccessFields(
        authType as AuthType,
        authValues,
        input.options?.components || [],
        input.optional || false,
        input.locked || false,
      );
    } else if (mode === 'auth') {
      return getAuthFields(
        authType as AuthType,
        authValues,
        input.options?.components || [],
        input.optional || false,
        input.locked || false,
      );
    }
    return [];
  }

  const getStartingValues = () => {
    // Pre-populate values from AuthFields, input, and inputsMap in order of precedence
    const fieldDefaultValues = authFields.reduce(
      (acc, field) => ({ ...acc, [field.name]: field.default }),
      {},
    ) as Auth;
    const inputDefaultValues = parseJson(input.default);
    const inputStartingValues = parseJson(input.value);
    const inputsMapValues = parseJson(inputsMap.get(input.name));

    return {
      ...fieldDefaultValues,
      ...inputDefaultValues,
      ...inputStartingValues,
      ...inputsMapValues,
    } as Auth;
  };

  const updateAuthType = (map: Map<string, unknown>) => {
    setAuthType(map.get('auth_type') as string);
    updateAuthInputsMap(map);
  };

  const updateAuthInputsMap = (map: Map<string, unknown>) => {
    setAuthValues(map);

    // Set radio button input starting values to first option if not already set to something
    authFields.forEach((field) => {
      if (field.type === 'radio' && !map.get(field.name) && field.options?.list_options) {
        map.set(field.name, field.options?.list_options[0].value);
      }
    });

    // Update inputsMap while maintaining hidden values
    if (authValuesPopulated) {
      const inputsWithValues = new Map();
      authValues.forEach((inputValue, inputName) => {
        if (inputValue) {
          inputsWithValues.set(inputName, inputValue);
        }
      });
      let stringifiedValues = JSON.stringify(Object.fromEntries(inputsWithValues));
      if (mode === 'access') {
        const combinedStartingValues = getStartingValues();
        const accessValuesObject = Object.fromEntries(authValues) as Auth;
        const combinedValues = { ...combinedStartingValues, ...accessValuesObject };
        stringifiedValues = JSON.stringify(combinedValues);
      }

      inputsMap.set(input.name, stringifiedValues);
      setInputsMap(new Map(inputsMap));
    }
  };

  return (
    <ListItem>
      <Card variant="outlined" tabIndex={0} className={classes.authCard}>
        <CardContent>
          <InputLabel
            tabIndex={0}
            required={!input.optional}
            disabled={input.locked || readOnly}
            aria-disabled={input.locked || readOnly}
            className={classes.inputLabel}
          >
            <FieldLabel input={input} />
          </InputLabel>
          {input.description && (
            <Markdown className={classes.inputDescription} remarkPlugins={[remarkGfm]}>
              {input.description}
            </Markdown>
          )}
          <List>
            <AuthTypeSelector
              input={input}
              index={index}
              inputsMap={authValues}
              setInputsMap={updateAuthType}
              key={`input-${index}`}
            />
          </List>
          <InputFields
            inputs={authFields}
            inputsMap={authValues}
            setInputsMap={updateAuthInputsMap}
          />
        </CardContent>
      </Card>
    </ListItem>
  );
};

export default InputAuth;
