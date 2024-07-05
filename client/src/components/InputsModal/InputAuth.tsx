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

  const defaultValues = JSON.parse(requirement.default as string) as Auth;
  const startingValues = JSON.parse(requirement.value as string) as Auth;
  const combinedStartingValues = { ...defaultValues, ...startingValues } as Auth;

  const authSelectorSettings = requirement.options?.components
    ? requirement.options?.components[0]
    : // Default auth type settings
      {
        name: 'auth_type',
        default: 'public',
      };

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

  const authFields = getAuthFields(
    authSelectorSettings.default as AuthType,
    requirement,
    authValues
  );

  // const getIsMissingInput = (field: InputAuthField) => {
  //   return (
  //     hasBeenModified[field.name as keyof typeof hasBeenModified] &&
  //     field.required &&
  //     !authBody[field.name as keyof Auth]
  //   );
  // };

  // Populate authValues on mount
  useEffect(() => {
    authFields.forEach((field: TestInput) => {
      authValues.set(field.name, combinedStartingValues[field.name as keyof Auth] || '');
    });
  }, []);

  useEffect(() => {
    console.log('requirement', requirement);
    console.log('req values', JSON.parse(requirement.value as string));
    console.log('auth values', authValues);

    const stringifiedAuthValues = JSON.stringify(authValues); // TODO: some parsing needed
    inputsMap.set(requirement.name, stringifiedAuthValues);
    setInputsMap(new Map(inputsMap));
  }, [authValues]);

  const handleAuthSelectionChange = (newValues: Map<string, unknown>, editStatus?: boolean) => {
    console.log('selection', newValues, editStatus);

    // (newInputsMap, editStatus) => setInputsMap(newInputsMap, editStatus);
  };

  return (
    <ListItem>
      <Box>
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
        {/* {authFields.map((field) => !field.hide && authField(field))} */}
        <InputFields inputs={authFields} inputsMap={authValues} setInputsMap={setAuthValues} />
      </Box>
    </ListItem>
  );
};

export default InputAuth;
