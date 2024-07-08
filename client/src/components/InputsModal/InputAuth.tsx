import React, { FC, useEffect } from 'react';
import { Box, List, ListItem, Typography } from '@mui/material';
import { Auth, TestInput } from '~/models/testSuiteModels';
import InputFields from './InputFields';
import useStyles from './styles';
import InputCombobox from './InputCombobox';
import { AuthType, getAuthFields } from './AuthSettings';

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

  const authSelectorSettings = requirement.options?.components
    ? requirement.options?.components[0]
    : // Default auth type settings
      {
        name: 'auth_type',
        default: 'public',
      };

  const [authFields, setAuthFields] = React.useState<TestInput[]>(
    getAuthFields(
      authSelectorSettings.default as AuthType,
      authValues,
      requirement.options?.components || []
    )
  );

  const authSelector: TestInput = {
    name: 'auth_type',
    type: 'select',
    title: `${requirement.name} Auth Type`,
    description: requirement.description,
    default: authSelectorSettings.default || 'public',
    optional: authSelectorSettings.optional,
    locked: authSelectorSettings.locked,
    options: {
      list_options: [
        {
          label: 'Public',
          value: 'public',
        },
        {
          label: 'Confidential Symmetric',
          value: 'symmetric',
        },
        {
          label: 'Confidential Asymmetric',
          value: 'asymmetric',
        },
        {
          label: 'Backend Services',
          value: 'backend_services',
        },
      ],
    },
  };

  useEffect(() => {
    // Pre-populate values from AuthFields, requirement, and inputsMap in order of precedence
    const fieldDefaultValues = authFields.reduce(
      (acc, field) => ({ ...acc, [field.name]: field.default }),
      {}
    ) as Auth;
    const requirementDefaultValues = JSON.parse(requirement.default as string) as Auth;
    const requirementStartingValues = JSON.parse(requirement.value as string) as Auth;
    const inputsMapValues = JSON.parse(inputsMap.get(requirement.name) as string) as Auth;
    const combinedStartingValues = {
      ...fieldDefaultValues,
      ...requirementDefaultValues,
      ...requirementStartingValues,
      ...inputsMapValues,
    } as Auth;

    // Populate authValues on mount
    authFields.forEach((field: TestInput) => {
      authValues.set(field.name, combinedStartingValues[field.name as keyof Auth] || '');
    });
    setAuthValuesPopulated(true);

    // Trigger change on mount for default values
    const authValuesCopy = new Map(authValues);
    setAuthValues(authValuesCopy);
  }, []);

  useEffect(() => {
    setAuthFields(
      getAuthFields(
        authSelectorSettings.default as AuthType,
        authValues,
        requirement.options?.components || []
      )
    );

    // Update inputsMap
    if (authValuesPopulated) {
      const stringifiedAuthValues = JSON.stringify(Object.fromEntries(authValues));
      inputsMap.set(requirement.name, stringifiedAuthValues);
      setInputsMap(new Map(inputsMap));
    }
  }, [authValues]);

  useEffect(() => {
    // TODO: fix serial inputs
  }, [inputsMap]);

  return (
    <ListItem sx={{ p: 0 }}>
      <Box width="100%">
        {requirement.description && (
          <Typography variant="subtitle1" component="p" className={classes.inputDescription}>
            {requirement.description}
          </Typography>
        )}
        <List>
          <InputCombobox
            requirement={authSelector}
            index={index}
            inputsMap={authValues}
            setInputsMap={setAuthValues}
            key={`input-${index}`}
          />
        </List>
        <InputFields inputs={authFields} inputsMap={authValues} setInputsMap={setAuthValues} />
      </Box>
    </ListItem>
  );
};

export default InputAuth;
