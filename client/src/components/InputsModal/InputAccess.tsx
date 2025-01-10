import React, { FC, useEffect } from 'react';
import { Card, CardContent, InputLabel, List, ListItem } from '@mui/material';
import Markdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { Auth, TestInput } from '~/models/testSuiteModels';
import { AuthType, getAccessFields } from '~/components/InputsModal/AuthSettings';
import FieldLabel from '~/components/InputsModal/FieldLabel';
import InputFields from '~/components/InputsModal/InputFields';
import useStyles from './styles';
import AuthTypeSelector from './AuthTypeSelector';

export interface InputAccessProps {
  input: TestInput;
  index: number;
  inputsMap: Map<string, unknown>;
  setInputsMap: (map: Map<string, unknown>, edited?: boolean) => void;
}

const InputAccess: FC<InputAccessProps> = ({ input, index, inputsMap, setInputsMap }) => {
  const { classes } = useStyles();
  const [accessValues, setAccessValues] = React.useState<Map<string, unknown>>(new Map());
  const [accessValuesPopulated, setAccessValuesPopulated] = React.useState<boolean>(false);

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

  const [accessFields, setAccessFields] = React.useState<TestInput[]>(
    getAccessFields(authType as AuthType, accessValues, input.options?.components || []),
  );

  useEffect(() => {
    // Set defaults on radio buttons
    // This is necessary because radio buttons with no preset defaults will still cause
    // missing input errors
    setAccessFields(
      accessFields.map((field) => {
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

    // Populate accessValues on mount
    accessValues.set('auth_type', authType);
    accessFields.forEach((field: TestInput) => {
      accessValues.set(field.name, combinedStartingValues[field.name as keyof Auth] || '');
    });
    setAccessValuesPopulated(true);

    // Trigger change on mount for default values
    const accessValuesCopy = new Map(accessValues);
    setAccessValues(accessValuesCopy);
  }, []);

  useEffect(() => {
    // Recalculate hidden fields
    setAccessFields(
      getAccessFields(authType as AuthType, accessValues, input.options?.components || []),
    );

    // Update inputsMap while maintaining hidden values
    if (accessValuesPopulated) {
      const combinedStartingValues = getStartingValues();
      const accessValuesObject = Object.fromEntries(accessValues) as Auth;
      const combinedValues = { ...combinedStartingValues, ...accessValuesObject };
      const stringifiedAccessValues = JSON.stringify(combinedValues);
      inputsMap.set(input.name, stringifiedAccessValues);
      setInputsMap(new Map(inputsMap));
    }
  }, [accessValues]);

  const getStartingValues = () => {
    // Pre-populate values from AuthFields, input, and inputsMap in order of precedence
    const fieldDefaultValues = accessFields.reduce(
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
    setAccessValues(map);
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
              inputsMap={accessValues}
              setInputsMap={updateAuthType}
              key={`input-${index}`}
            />
          </List>
          <InputFields
            inputs={accessFields}
            inputsMap={accessValues}
            setInputsMap={setAccessValues}
          />
        </CardContent>
      </Card>
    </ListItem>
  );
};

export default InputAccess;
