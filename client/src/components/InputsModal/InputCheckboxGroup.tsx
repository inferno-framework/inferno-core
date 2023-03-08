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
    // Default values should be in form { value: true/false }
    let startingValues = inputsMap.get(requirement.name) || requirement.default;
    if (!startingValues) {
      // Instantiate with { ..., [option.value]: false } for all option values
      const options = requirement.options?.list_options;
      if (options && options.length > 0) {
        startingValues = options.reduce(
          (acc, option) => ((acc[option.value] = false), acc),
          {} as CheckboxValues
        );
      }
    }
    return startingValues as CheckboxValues;
  });

  useEffect(() => {
    // Make sure starting values get set in inputsMap
    inputsMap.set(requirement.name, values);
    setInputsMap(new Map(inputsMap));
  }, []);

  const handleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setValues({
      ...values,
      [event.target.name]: event.target.checked,
    });
    inputsMap.set(requirement.name, values);
    setInputsMap(new Map(inputsMap));
  };

  return (
    <ListItem>
      <FormControl
        component="fieldset"
        id={`requirement${index}_input`}
        disabled={requirement.locked}
        fullWidth
      >
        <FormLabel className={styles.inputLabel}>
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
