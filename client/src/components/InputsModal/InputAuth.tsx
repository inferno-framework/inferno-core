import React, { FC, useEffect } from 'react';
import { Box, List, ListItem, Typography } from '@mui/material';
import { Auth, TestInput } from '~/models/testSuiteModels';
import InputFields from './InputFields';
import useStyles from './styles';
import { AuthType, getAuthFields } from './AuthSettings';
import AuthTypeSelector from './AuthTypeSelector';

export interface InputAuthProps {
  requirement: TestInput;
  index: number;
  inputsMap: Map<string, unknown>;
  setInputsMap: (map: Map<string, unknown>, edited?: boolean) => void;
}

const InputAuth: FC<InputAuthProps> = ({ requirement, index, inputsMap, setInputsMap }) => {
  const { classes } = useStyles();
  const [authValues, setAuthValues] = React.useState<Map<string, unknown>>(new Map());
  const [authValuesPopulated, setAuthValuesPopulated] = React.useState<boolean>(false);

  // Default auth type settings
  const [authType, setAuthType] = React.useState<string>(
    requirement.options?.components
      ? (requirement.options?.components[0].default as string)
      : 'public',
  );

  const [authFields, setAuthFields] = React.useState<TestInput[]>(
    getAuthFields(authType as AuthType, authValues, requirement.options?.components || []),
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
    setAuthFields(
      getAuthFields(authType as AuthType, authValues, requirement.options?.components || []),
    );

    // Update inputsMap
    if (authValuesPopulated) {
      const stringifiedAuthValues = JSON.stringify(Object.fromEntries(authValues));
      inputsMap.set(requirement.name, stringifiedAuthValues);
      setInputsMap(new Map(inputsMap));
    }
  }, [authValues]);

  const getStartingValues = () => {
    // Pre-populate values from AuthFields, requirement, and inputsMap in order of precedence
    const fieldDefaultValues = authFields.reduce(
      (acc, field) => ({ ...acc, [field.name]: field.default }),
      {},
    ) as Auth;
    const requirementDefaultValues =
      requirement.default && typeof requirement.default === 'string'
        ? (JSON.parse(requirement.default) as Auth)
        : {};
    const requirementStartingValues =
      requirement.value && typeof requirement.value === 'string'
        ? (JSON.parse(requirement.value) as Auth)
        : {};
    const inputsMapValues = inputsMap.get(requirement.name)
      ? (JSON.parse(inputsMap.get(requirement.name) as string) as Auth)
      : {};

    return {
      ...fieldDefaultValues,
      ...requirementDefaultValues,
      ...requirementStartingValues,
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
        {requirement.description && (
          <Typography variant="subtitle1" component="p" className={classes.inputDescription}>
            {requirement.description}
          </Typography>
        )}
        <List>
          <AuthTypeSelector
            requirement={requirement}
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
