import React, { FC, useEffect } from 'react';
import {
  Checkbox,
  FormControl,
  FormControlLabel,
  FormGroup,
  FormLabel,
  ListItem,
} from '@mui/material';
import { CheckboxValues, TestInput } from '~/models/testSuiteModels';
import FieldLabel from './FieldLabel';
import useStyles from './styles';

export interface InputCheckboxGroupProps {
  requirement: TestInput;
  index: number;
  inputsMap: Map<string, unknown>;
  setInputsMap: (map: Map<string, unknown>) => void;
}

const InputCheckboxGroup: FC<InputCheckboxGroupProps> = ({
  requirement,
  index,
  inputsMap,
  setInputsMap,
}) => {
  const styles = useStyles();

  const [values, setValues] = React.useState<CheckboxValues>(() => {
    // Default values should be in form ['value'] where all values are checked
    const inputMapValues = Array.isArray(inputsMap.get(requirement.name))
      ? inputsMap.get(requirement.name)
      : [inputsMap.get(requirement.name)]; // expecting single value
    const defaultValues = inputMapValues || requirement.default || [];
    const options = requirement.options?.list_options;

    let startingValues = {};
    // Convert array of checked values to map from item name to checked status
    if (options && options.length > 0) {
      startingValues = options.reduce(
        (acc, option) => (
          (acc[option.value] = Array.isArray(defaultValues)
            ? defaultValues.includes(option.value)
            : false), // default to false if defaultValues is not an array of checked values
          acc
        ),
        {} as CheckboxValues
      );
    }

    return startingValues as CheckboxValues;
  });

  useEffect(() => {
    // Make sure starting values get set in inputsMap
    inputsMap.set(requirement.name, transformValuesToArray(values));
    setInputsMap(new Map(inputsMap));
  }, []);

  const handleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const newValues = {
      ...values,
      [event.target.name]: event.target.checked,
    };
    inputsMap.set(requirement.name, transformValuesToArray(newValues));
    setInputsMap(new Map(inputsMap));
    setValues(newValues);
  };

  // Convert map from item name to checked status back to array of checked values
  const transformValuesToArray = (values: CheckboxValues): string[] => {
    return Object.entries(values)
      .filter(([, value]) => value === true)
      .map(([key]) => key);
  };

  return (
    <ListItem>
      <FormControl
        component="fieldset"
        id={`requirement${index}_input`}
        disabled={requirement.locked}
        fullWidth
      >
        <FormLabel required={!requirement.optional} className={styles.inputLabel}>
          <FieldLabel requirement={requirement} />
        </FormLabel>
        <FormGroup aria-label={`${requirement.name}-checkboxes-group`}>
          {requirement.options?.list_options?.map((option, i) => (
            <FormControlLabel
              control={
                <Checkbox
                  size="small"
                  name={option.value}
                  checked={values[option.value as keyof CheckboxValues] || false}
                  onChange={handleChange}
                />
              }
              label={option.label}
              key={`checkbox-${i}`}
            />
          ))}
        </FormGroup>
      </FormControl>
    </ListItem>
  );
};

export default InputCheckboxGroup;
