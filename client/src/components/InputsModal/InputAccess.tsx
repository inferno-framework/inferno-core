import React, { FC, useEffect } from 'react';
import { Card, CardContent, InputLabel, ListItem, Typography } from '@mui/material';
import { Auth, TestInput } from '~/models/testSuiteModels';
import { AuthType, getAccessFields } from '~/components/InputsModal/AuthSettings';
import FieldLabel from '~/components/InputsModal/FieldLabel';
import InputFields from '~/components/InputsModal/InputFields';
import useStyles from './styles';

export interface InputAccessProps {
  requirement: TestInput;
  inputsMap: Map<string, unknown>;
  setInputsMap: (map: Map<string, unknown>, edited?: boolean) => void;
}

const InputAccess: FC<InputAccessProps> = ({ requirement, inputsMap, setInputsMap }) => {
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

  useEffect(() => {
    // Populate accessValues on mount
    const defaultValues = JSON.parse(requirement.default as string) as Auth;
    accessFields.forEach((field: TestInput) => {
      accessValues.set(field.name, defaultValues[field.name as keyof Auth] || '');
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

    // Update inputsMap whihle maintaining hidden values
    if (accessValuesPopulated) {
      const defaultValues = JSON.parse(requirement.default as string) as Auth;
      const accessValuesObject = Object.fromEntries(accessValues) as Auth;
      const combinedValues = { ...defaultValues, ...accessValuesObject };
      const stringifiedAccessValues = JSON.stringify(combinedValues);
      inputsMap.set(requirement.name, stringifiedAccessValues);
      setInputsMap(new Map(inputsMap));
    }
  }, [accessValues]);

  useEffect(() => {
    // TODO: fix serial inputs
  }, [inputsMap]);

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
