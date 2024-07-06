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

const InputAuth: FC<InputAuthProps> = ({ requirement, /* index, */ inputsMap, setInputsMap }) => {
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

  // const [hasBeenModified, setHasBeenModified] = React.useState({});

  //   name: string;
  //   title?: string;
  //   value?: unknown;
  //   type?: 'auth_info' | 'oauth_credentials' | 'checkbox' | 'radio' | 'text' | 'textarea';
  //   description?: string;
  //   default?: string | string[];
  //   optional?: boolean;
  //   locked?: boolean;
  //   options?: {
  //     components?: TestInput[];
  //     list_options?: InputOption[];
  //     mode?: string;
  //   };

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

  // const getIsMissingInput = (field: InputAuthField) => {
  //   return (
  //     hasBeenModified[field.name as keyof typeof hasBeenModified] &&
  //     field.required &&
  //     !authBody[field.name as keyof Auth]
  //   );
  // };

  useEffect(() => {
    console.log(requirement);

    // Populate authValues on mount
    const defaultValues = JSON.parse(requirement.default as string) as Auth;
    authFields.forEach((field: TestInput) => {
      authValues.set(field.name, defaultValues[field.name as keyof Auth] || '');
    });
    // ...(requirement.options?.components?.slice(1, requirement.options?.components.length) || []),

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

  const handleAuthSelectionChange = (newValues: Map<string, unknown>, editStatus?: boolean) => {
    console.error('selection', newValues, editStatus, requirement, inputsMap.get(requirement.name));
    // inputsMap.get(requirement.name);
    // setInputsMap(newValues, editStatus);
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
            index={0}
            inputsMap={inputsMap}
            setInputsMap={handleAuthSelectionChange}
            key={`input-${0}`}
          />
        </List>
        <InputFields inputs={authFields} inputsMap={authValues} setInputsMap={setAuthValues} />
      </Box>
    </ListItem>
  );
};

export default InputAuth;
