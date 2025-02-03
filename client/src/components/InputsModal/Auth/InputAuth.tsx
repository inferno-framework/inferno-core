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
import useStyles from '../styles';

export interface InputAuthProps {
  mode: 'access' | 'auth';
  input: TestInput;
  index: number;
  inputsMap: Map<string, unknown>;
  setInputsMap: (map: Map<string, unknown>, edited?: boolean) => void;
}

const parseJson = (jsonInput: unknown) => {
  return jsonInput && typeof jsonInput === 'string' ? (JSON.parse(jsonInput) as Auth) : {};
};

const InputAuth: FC<InputAuthProps> = ({ mode, input, index, inputsMap, setInputsMap }) => {
  const { classes } = useStyles();
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
  let fields: TestInput[] = [];
  if (mode === 'access') {
    fields = getAccessFields(
      authType as AuthType,
      authValues,
      input.options?.components || [],
      input.locked || false,
    );
  } else if (mode === 'auth') {
    fields = getAuthFields(
      authType as AuthType,
      authValues,
      input.options?.components || [],
      input.locked || false,
    );
  }
  const [authFields, setAuthFields] = React.useState<TestInput[]>(fields);

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

    // Trigger change on mount for default values
    const authValuesCopy = new Map(authValues);
    setAuthValues(authValuesCopy);
  }, []);

  useEffect(() => {
    // Recalculate hidden fields
    if (mode === 'access') {
      setAuthFields(
        getAccessFields(
          authType as AuthType,
          authValues,
          input.options?.components || [],
          input.locked || false,
        ),
      );
    } else if (mode === 'auth') {
      setAuthFields(
        getAuthFields(
          authType as AuthType,
          authValues,
          input.options?.components || [],
          input.locked || false,
        ),
      );
    }

    // Update inputsMap while maintaining hidden values
    if (authValuesPopulated) {
      let stringifiedValues = JSON.stringify(Object.fromEntries(authValues));
      if (mode === 'access') {
        const combinedStartingValues = getStartingValues();
        const accessValuesObject = Object.fromEntries(authValues) as Auth;
        const combinedValues = { ...combinedStartingValues, ...accessValuesObject };
        stringifiedValues = JSON.stringify(combinedValues);
      }
      inputsMap.set(input.name, stringifiedValues);
      setInputsMap(new Map(inputsMap));
    }
  }, [authValues]);

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
    setAuthValues(map);
  };

  return (
    <ListItem>
      <Card variant="outlined" className={classes.authCard}>
        <CardContent>
          <InputLabel
            required={!input.optional}
            disabled={input.locked}
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
          <InputFields inputs={authFields} inputsMap={authValues} setInputsMap={setAuthValues} />
        </CardContent>
      </Card>
    </ListItem>
  );
};

export default InputAuth;
