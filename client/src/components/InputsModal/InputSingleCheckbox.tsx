import React, { FC, useEffect } from 'react';
import {
  Checkbox,
  FormControl,
  FormControlLabel,
  FormGroup,
  // FormLabel,
  ListItem,
  Typography,
} from '@mui/material';
import { TestInput } from '~/models/testSuiteModels';
// import FieldLabel from './FieldLabel';
import useStyles from './styles';
import { InputAuthField } from './InputAuth';

export interface InputSingleCheckboxProps {
  requirement: TestInput | InputAuthField;
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

  const [value, setValue] = React.useState<boolean>(() => {
    // Default value should be true or false
    return !!requirement.default || false;
  });

  const isMissingInput =
    hasBeenModified && !requirement.optional && inputsMap.get(requirement.name) === '[]';

  useEffect(() => {
    // Make sure starting values get set in inputsMap
    inputsMap.set(requirement.name, value);
    setInputsMap(new Map(inputsMap), false);
  }, []);

  const handleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const newValue = event.target.checked;
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
          <Typography variant="subtitle1" className={classes.inputDescription}>
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
            label={requirement.label || requirement.title || ''}
            key={`checkbox-${requirement.name}`}
          />
        </FormGroup>
      </FormControl>
    </ListItem>
  );
};

export default InputSingleCheckbox;
