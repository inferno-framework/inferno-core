import React, { FC, useEffect } from 'react';
import {
  Checkbox,
  FormControl,
  FormControlLabel,
  FormGroup,
  ListItem,
  Typography,
} from '@mui/material';
import { TestInput } from '~/models/testSuiteModels';
import FieldLabel from '~/components/InputsModal/FieldLabel';
import useStyles from '~/components/InputsModal/styles';

export interface InputSingleCheckboxProps {
  requirement: TestInput;
  index: number;
  inputsMap: Map<string, unknown>;
  setInputsMap: (map: Map<string, unknown>, edited?: boolean) => void;
}

// Manage this component in strings to remain consistent with eventual request body
export type BooleanString = 'true' | 'false';

const InputSingleCheckbox: FC<InputSingleCheckboxProps> = ({
  requirement,
  index,
  inputsMap,
  setInputsMap,
}) => {
  const { classes } = useStyles();
  const [hasBeenModified, setHasBeenModified] = React.useState(false);
  const [value, setValue] = React.useState<BooleanString>(() => {
    // Default value should be true or false
    if (requirement.default) return requirement.default as BooleanString;
    return 'false'; // return false if undefined
  });

  const isMissingInput =
    hasBeenModified && !requirement.optional && inputsMap.get(requirement.name) === false;

  const fieldLabel = (
    <>
      <FieldLabel requirement={requirement} isMissingInput={isMissingInput} />{' '}
      {requirement.optional ? '' : '*'}
    </>
  );

  useEffect(() => {
    // Make sure starting values get set in inputsMap
    inputsMap.set(requirement.name, value);
    setInputsMap(new Map(inputsMap), false);
  }, []);

  const handleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const newValue = event.target.checked.toString() as BooleanString;
    inputsMap.set(requirement.name, newValue);
    setInputsMap(new Map(inputsMap));
    setValue(newValue);
    setHasBeenModified(true);
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
        {requirement.description && (
          <Typography variant="subtitle1" component="p" className={classes.inputDescription}>
            {requirement.description}
          </Typography>
        )}
        {/* TODO: required means set to true and locked? */}
        <FormGroup aria-label={`${requirement.name}-single-checkbox`}>
          <FormControlLabel
            control={
              <Checkbox
                size="small"
                color="secondary"
                checked={value === 'true'}
                onBlur={(e) => {
                  if (e.currentTarget === e.target) {
                    setHasBeenModified(true);
                  }
                }}
                onChange={handleChange}
              />
            }
            label={fieldLabel}
            key={`checkbox-${requirement.name}`}
          />
        </FormGroup>
      </FormControl>
    </ListItem>
  );
};

export default InputSingleCheckbox;
