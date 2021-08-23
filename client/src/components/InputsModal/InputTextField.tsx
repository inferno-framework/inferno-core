import { InputAdornment, ListItem, TextField, Zoom } from '@material-ui/core';
import { TestInput } from 'models/testSuiteModels';
import RequiredInputWarning from './RequiredInputWarning';
import React, { FC } from 'react';
import useStyles from './styles';

export interface InputTextFieldProps {
  requirement: TestInput;
  index: number;
  inputsMap: Map<string, string>;
  setInputsMap: (map: Map<string, string>) => void;
}

const InputTextField: FC<InputTextFieldProps> = ({
  requirement,
  index,
  inputsMap,
  setInputsMap,
}) => {
  const value = inputsMap.get(requirement.name);
  const styles = useStyles();
  const missingRequired = !requirement.optional && value?.length == 0;
  const requiredWarning = (
    <Zoom in={missingRequired}>
      <InputAdornment position="end">
        <RequiredInputWarning />
      </InputAdornment>
    </Zoom>
  );
  return (
    <ListItem key={`requirement${index}`}>
      <TextField
        id={`requirement${index}_input`}
        className={styles.inputField}
        fullWidth
        label={requirement.title || requirement.name}
        helperText={requirement.description}
        value={inputsMap.get(requirement.name)}
        InputProps={{
          endAdornment: requiredWarning,
        }}
        onChange={(event) => {
          const value = event.target.value;
          inputsMap.set(requirement.name, value);
          setInputsMap(new Map(inputsMap));
        }}
      />
    </ListItem>
  );
};

export default InputTextField;
