import React, { FC } from 'react';
import { FormControl, FormLabel, Input, ListItem, Typography } from '@mui/material';
import { TestInput } from '~/models/testSuiteModels';
import FieldLabel from './FieldLabel';
import useStyles from './styles';

export interface InputTextFieldProps {
  requirement: TestInput;
  index: number;
  inputsMap: Map<string, unknown>;
  setInputsMap: (map: Map<string, unknown>, edited?: boolean) => void;
  showMultiline?: boolean;
}

const InputTextField: FC<InputTextFieldProps> = ({
  requirement,
  index,
  inputsMap,
  setInputsMap,
  showMultiline,
}) => {
  const { classes } = useStyles();
  const [hasBeenModified, setHasBeenModified] = React.useState(false);

  const isMissingInput =
    hasBeenModified && !requirement.optional && !inputsMap.get(requirement.name);

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
        <FormLabel htmlFor={`requirement${index}_input`} className={classes.inputLabel}>
          <FieldLabel requirement={requirement} isMissingInput={isMissingInput} />
        </FormLabel>
        {requirement.description && (
          <Typography variant="subtitle1" className={classes.inputDescription}>
            {requirement.description}
          </Typography>
        )}
        <Input
          disabled={requirement.locked}
          required={!requirement.optional}
          error={isMissingInput}
          id={`requirement${index}_input`}
          className={classes.inputField}
          color="secondary"
          fullWidth
          multiline={showMultiline}
          rows={showMultiline ? 4 : 1}
          value={inputsMap.get(requirement.name)}
          onBlur={(e) => {
            if (e.currentTarget === e.target) {
              setHasBeenModified(true);
            }
          }}
          onChange={(event) => {
            const value = event.target.value;
            inputsMap.set(requirement.name, value);
            setInputsMap(new Map(inputsMap));
          }}
        />
      </FormControl>
    </ListItem>
  );
};

export default InputTextField;
