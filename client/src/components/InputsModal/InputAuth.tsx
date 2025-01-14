import React, { FC, useEffect } from 'react';
import { Box, List, ListItem } from '@mui/material';
import Markdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { Auth, TestInput } from '~/models/testSuiteModels';
import { AuthType, getAuthFields } from '~/components/InputsModal/AuthSettings';
import AuthTypeSelector from '~/components/InputsModal/AuthTypeSelector';
import InputFields from '~/components/InputsModal/InputFields';
import useStyles from './styles';

export interface InputAuthProps {
  input: TestInput;
  index: number;
  inputsMap: Map<string, unknown>;
  setInputsMap: (map: Map<string, unknown>, edited?: boolean) => void;
}

const InputAuth: FC<InputAuthProps> = ({ input, index, inputsMap, setInputsMap }) => {
  const { classes } = useStyles();
  const [authValues, setAuthValues] = React.useState<Map<string, unknown>>(new Map());
  const [authValuesPopulated, setAuthValuesPopulated] = React.useState<boolean>(false);

  // Default auth type settings
  const authComponent = input.options?.components?.find(
    (component) => component.name === 'auth_type',
  );

  const firstListOption =
    authComponent?.options?.list_options && authComponent?.options?.list_options?.length > 0
      ? authComponent?.options?.list_options[0].value
      : undefined;

  const [authType, setAuthType] = React.useState<string>(
    (authComponent?.default || firstListOption || 'public') as string,
  );

  const [authFields, setAuthFields] = React.useState<TestInput[]>(
    getAuthFields(authType as AuthType, authValues, input.options?.components || []),
  );

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

    // Populate authValues on mount
    authValues.set('auth_type', authType);
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
    setAuthFields(getAuthFields(authType as AuthType, authValues, input.options?.components || []));

    // Update inputsMap
    if (authValuesPopulated) {
      const stringifiedAuthValues = JSON.stringify(Object.fromEntries(authValues));
      inputsMap.set(input.name, stringifiedAuthValues);
      setInputsMap(new Map(inputsMap));
    }
  }, [authValues]);

  const getStartingValues = () => {
    // Pre-populate values from AuthFields, input, and inputsMap in order of precedence
    const fieldDefaultValues = authFields.reduce(
      (acc, field) => ({ ...acc, [field.name]: field.default }),
      {},
    ) as Auth;
    const inputDefaultValues =
      input.default && typeof input.default === 'string' ? (JSON.parse(input.default) as Auth) : {};
    const inputStartingValues =
      input.value && typeof input.value === 'string' ? (JSON.parse(input.value) as Auth) : {};
    const inputsMapValues = inputsMap.get(input.name)
      ? (JSON.parse(inputsMap.get(input.name) as string) as Auth)
      : {};

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
    <ListItem sx={{ p: 0 }}>
      <Box width="100%">
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
      </Box>
    </ListItem>
  );
};

export default InputAuth;
