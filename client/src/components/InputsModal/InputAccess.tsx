import React, { FC, useEffect } from 'react';
import { Card, CardContent, InputLabel, List, ListItem, Typography } from '@mui/material';
import { Auth, TestInput } from '~/models/testSuiteModels';
import { AuthType, getAccessFields } from '~/components/InputsModal/AuthSettings';
import FieldLabel from '~/components/InputsModal/FieldLabel';
import InputFields from '~/components/InputsModal/InputFields';
import useStyles from './styles';
import InputCombobox from './InputCombobox';

export interface InputAccessProps {
  requirement: TestInput;
  index: number;
  inputsMap: Map<string, unknown>;
  setInputsMap: (map: Map<string, unknown>, edited?: boolean) => void;
}

const InputAccess: FC<InputAccessProps> = ({ requirement, index, inputsMap, setInputsMap }) => {
  const { classes } = useStyles();
  const [accessValues, setAccessValues] = React.useState<Map<string, unknown>>(new Map());
  const [accessValuesPopulated, setAccessValuesPopulated] = React.useState<boolean>(false);

  const accessSelectorSettings = requirement.options?.components
    ? requirement.options?.components[0]
    : // Default auth type settings
      {
        name: 'auth_type',
        default: 'public',
      };

  const [accessFields, setAccessFields] = React.useState<TestInput[]>(
    getAccessFields(
      accessSelectorSettings.default as AuthType,
      accessValues,
      requirement.options?.components || []
    )
  );

  const accessSelector: TestInput = {
    name: 'auth_type',
    type: 'select',
    title: `${requirement.name} Auth Type`,
    description: requirement.description,
    default: accessSelectorSettings.default || 'public',
    optional: accessSelectorSettings.optional,
    locked: accessSelectorSettings.locked,
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
    const combinedStartingValues = getStartingValues();

    // Populate accessValues on mount
    accessValues.set('auth_type', accessSelectorSettings.default);
    accessFields.forEach((field: TestInput) => {
      accessValues.set(field.name, combinedStartingValues[field.name as keyof Auth] || '');
    });
    setAccessValuesPopulated(true);

    // Trigger change on mount for default values
    const accessValuesCopy = new Map(accessValues);
    setAccessValues(accessValuesCopy);
  }, []);

  useEffect(() => {
    setAccessFields(
      getAccessFields(
        accessSelectorSettings.default as AuthType,
        accessValues,
        requirement.options?.components || []
      )
    );

    // Update inputsMap while maintaining hidden values
    if (accessValuesPopulated) {
      const combinedStartingValues = getStartingValues();
      const accessValuesObject = Object.fromEntries(accessValues) as Auth;
      const combinedValues = { ...combinedStartingValues, ...accessValuesObject };
      const stringifiedAccessValues = JSON.stringify(combinedValues);
      inputsMap.set(requirement.name, stringifiedAccessValues);
      setInputsMap(new Map(inputsMap));
    }
  }, [accessValues]);

  const getStartingValues = () => {
    // Pre-populate values from AuthFields, requirement, and inputsMap in order of precedence
    const fieldDefaultValues = accessFields.reduce(
      (acc, field) => ({ ...acc, [field.name]: field.default }),
      {}
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

  return (
    <ListItem>
      <Card variant="outlined" className={classes.authCard}>
        <CardContent>
          <InputLabel
            required={!requirement.optional}
            disabled={requirement.locked}
            className={classes.inputLabel}
          >
            <FieldLabel requirement={requirement} />
          </InputLabel>
          {requirement.description && (
            <Typography variant="subtitle1" component="p" className={classes.inputDescription}>
              {requirement.description}
            </Typography>
          )}
          <List>
            <InputCombobox
              requirement={accessSelector}
              index={index}
              inputsMap={accessValues}
              setInputsMap={setAccessValues}
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
