import { ListItem, TextField } from '@material-ui/core';
import { TestInput } from 'models/testSuiteModels';
import React, { FC, Fragment } from 'react';
import useStyles from './styles';

export interface InputTextAreaProps {
  requirement: TestInput;
  index: number;
  inputsMap: Map<string, string>;
  setInputsMap: (map: Map<string, string>) => void;
}

const InputTextArea: FC<InputTextAreaProps> = ({ requirement, index, inputsMap, setInputsMap }) => {
  const styles = useStyles();
  const fieldLabel = requirement.optional ? (
    requirement.title || requirement.name
  ) : (
    <Fragment>
      {requirement.title || requirement.name}
      <span className={styles.requiredLabel}> (required)</span>
    </Fragment>
  );
  return (
    <ListItem>
      <TextField
        id={`requirement${index}_input`}
        className={styles.inputField}
        fullWidth
        label={fieldLabel}
        helperText={requirement.description}
        value={inputsMap.get(requirement.name)}
        multiline
        rows={4}
        onChange={(event) => {
          const value = event.target.value;
          inputsMap.set(requirement.name, value);
          setInputsMap(new Map(inputsMap));
        }}
      />
    </ListItem>
  );
};

export default InputTextArea;
