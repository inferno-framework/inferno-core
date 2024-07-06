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
    // Populate authValues on mount
    const defaultValues = JSON.parse(requirement.default as string) as Auth;
    authFields.forEach((field: TestInput) => {
      authValues.set(field.name, defaultValues[field.name as keyof Auth] || '');
    });
    setAuthValuesPopulated(true);
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

  const handleAuthSelectionChange = (newValues: Map<string, unknown>, editStatus?: boolean) => {
    console.error(newValues, editStatus);
    // TODO: Update this when inputsMap can be updated with the auth_type
  };

  return (
    <ListItem>
      <Box width="100%">
        {requirement.description && (
          <Typography variant="subtitle1" className={classes.inputDescription}>
            {requirement.description}
          </Typography>
        )}
        <List>
          <InputCombobox
            requirement={authSelector}
            index={index}
            inputsMap={authValues}
            setInputsMap={handleAuthSelectionChange}
            key={`input-${index}`}
          />
        </List>
        <InputFields inputs={authFields} inputsMap={authValues} setInputsMap={setAuthValues} />
      </Box>
    </ListItem>
  );
};

export default InputAuth;
