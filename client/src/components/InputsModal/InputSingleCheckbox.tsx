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

const InputSingleCheckbox: FC<InputSingleCheckboxProps> = ({
  requirement,
  index,
  inputsMap,
  setInputsMap,
}) => {
  const { classes } = useStyles();
  const [hasBeenModified, setHasBeenModified] = React.useState(false);
  const [value, setValue] = React.useState<boolean>(false);

  const isMissingInput =
    hasBeenModified && !requirement.optional && inputsMap.get(requirement.name) === false;

  // No "required" formatting because single checkboxes always have a value assigned
  const fieldLabel = <FieldLabel requirement={requirement} isMissingInput={isMissingInput} />;

  useEffect(() => {
    const inputsValue = inputsMap.get(requirement.name) as string;
    let startingValue = false;
    if (inputsValue === 'true') {
      startingValue = true;
    } else if (inputsValue !== 'false' && (requirement.default as string) === 'true') {
      startingValue = true;
    }
    setValue(startingValue);
  }, []);

  const handleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const newValue = event.target.checked;
    setValue(newValue);
    setHasBeenModified(true);
    inputsMap.set(requirement.name, newValue.toString());
    setInputsMap(new Map(inputsMap));
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
                checked={value}
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
