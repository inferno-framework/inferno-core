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
}

const InputTextField: FC<InputTextFieldProps> = ({
  requirement,
  index,
  inputsMap,
  setInputsMap,
}) => {
  const { classes } = useStyles();
  const [hasBeenModified, setHasBeenModified] = React.useState(false);

  const isMissingInput =
    hasBeenModified && !requirement.optional && !inputsMap.get(requirement.name);

  return (
    <ListItem>
      <FormControl
        component="fieldset"
        id={`requirement${index}_control`}
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
          <Typography variant="subtitle1" component="p" className={classes.inputDescription}>
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
          multiline={requirement.type === 'textarea'}
          minRows={requirement.type === 'textarea' ? 4 : 1}
          maxRows={20}
          value={inputsMap.get(requirement.name) || ''}
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
