import React, { FC, useEffect } from 'react';
import { Card, CardContent, InputLabel, ListItem, Typography } from '@mui/material';
import { Auth, TestInput } from '~/models/testSuiteModels';
import { getAccessFields } from '~/components/InputsModal/AuthSettings';
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

  const [accessFields, setAccessFields] = React.useState<TestInput[]>(
    getAccessFields(accessValues, requirement.options?.components || [])
  );

  useEffect(() => {
    const combinedStartingValues = getStartingValues();

    // Populate accessValues on mount
    accessFields.forEach((field: TestInput) => {
      accessValues.set(field.name, combinedStartingValues[field.name as keyof Auth] || '');
    });
    setAccessValuesPopulated(true);

    // Trigger change on mount for default values
    const accessValuesCopy = new Map(accessValues);
    setAccessValues(accessValuesCopy);
  }, []);

  useEffect(() => {
    setAccessFields(getAccessFields(accessValues, requirement.options?.components || []));

    // Update inputsMap whihle maintaining hidden values
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
