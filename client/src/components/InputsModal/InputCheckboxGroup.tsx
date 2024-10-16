import React, { FC, useEffect } from 'react';
import {
  Checkbox,
  FormControl,
  FormControlLabel,
  FormGroup,
  FormLabel,
  ListItem,
  Typography,
} from '@mui/material';
import { CheckboxValues, TestInput } from '~/models/testSuiteModels';
import FieldLabel from './FieldLabel';
import useStyles from './styles';

export interface InputCheckboxGroupProps {
  requirement: TestInput;
  index: number;
  inputsMap: Map<string, unknown>;
  setInputsMap: (map: Map<string, unknown>, edited?: boolean) => void;
}

const InputCheckboxGroup: FC<InputCheckboxGroupProps> = ({
  requirement,
  index,
  inputsMap,
  setInputsMap,
}) => {
  const { classes } = useStyles();
  const [hasBeenModified, setHasBeenModified] = React.useState(false);

  const [values, setValues] = React.useState<CheckboxValues>(() => {
    // Default values should be in form ['value'] where all values are checked
    let inputMapValues: string[] = [];
    try {
      // Parse JSON string of values
      inputMapValues = JSON.parse(inputsMap.get(requirement.name) as string) as string[];
      // eslint-disable-next-line @typescript-eslint/no-unused-vars
    } catch (e) {
      // If not JSON string, then either array or single value
      if (Array.isArray(inputsMap.get(requirement.name))) {
        inputMapValues = inputsMap.get(requirement.name) as string[];
      } else {
        inputMapValues = [inputsMap.get(requirement.name) as string]; // expecting single value
      }
    }

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
        {} as CheckboxValues,
      );
    }
    return startingValues as CheckboxValues;
  });

  const isMissingInput =
    hasBeenModified && !requirement.optional && inputsMap.get(requirement.name) === '[]';

  useEffect(() => {
    // Make sure starting values get set in inputsMap
    inputsMap.set(requirement.name, transformValuesToJSONArray(values));
    setInputsMap(new Map(inputsMap), false);
  }, []);

  const handleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const newValues = {
      ...values,
      [event.target.name]: event.target.checked,
    };
    inputsMap.set(requirement.name, transformValuesToJSONArray(newValues));
    setInputsMap(new Map(inputsMap));
    setValues(newValues);
    setHasBeenModified(true);
  };

  // Convert map from item name to checked status back to array of checked values
  const transformValuesToJSONArray = (values: CheckboxValues): string => {
    const checkedValues = Object.entries(values)
      .filter(([, value]) => value === true)
      .map(([key]) => key);

    // Stringify array before setting input map to prevent empty inputs setting default inputs
    return JSON.stringify(checkedValues);
  };

  return (
    <ListItem>
      <FormControl
        component="fieldset"
        id={`requirement${index}_input`}
        disabled={requirement.locked}
        required={!requirement.optional}
        error={isMissingInput}
        fullWidth
        className={classes.inputField}
      >
        <FormLabel className={classes.inputLabel}>
          <FieldLabel requirement={requirement} isMissingInput={isMissingInput} />
        </FormLabel>
        {requirement.description && (
          <Typography variant="subtitle1" component="p" className={classes.inputDescription}>
            {requirement.description}
          </Typography>
        )}
        <FormGroup aria-label={`${requirement.name}-checkboxes-group`}>
          {requirement.options?.list_options?.map((option, i) => (
            <FormControlLabel
              control={
                <Checkbox
                  size="small"
                  color="secondary"
                  name={option.value}
                  disabled={option.locked}
                  checked={values[option.value as keyof CheckboxValues] || false}
                  onBlur={(e) => {
                    if (e.currentTarget === e.target) {
                      setHasBeenModified(true);
                    }
                  }}
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
