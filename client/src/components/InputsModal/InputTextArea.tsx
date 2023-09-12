import React, { FC } from 'react';
import { ListItem, TextField } from '@mui/material';
import { TestInput } from '~/models/testSuiteModels';
import FieldLabel from './FieldLabel';
import useStyles from './styles';
import lightTheme from 'styles/theme';

export interface InputTextAreaProps {
  requirement: TestInput;
  index: number;
  inputsMap: Map<string, unknown>;
  setInputsMap: (map: Map<string, unknown>, edited?: boolean) => void;
}

const InputTextArea: FC<InputTextAreaProps> = ({ requirement, index, inputsMap, setInputsMap }) => {
  const { classes } = useStyles();
  const [hasBeenModified, setHasBeenModified] = React.useState(false);

  return (
    <ListItem>
      <TextField
        disabled={requirement.locked}
        required={!requirement.optional}
        error={hasBeenModified && !requirement.optional && !inputsMap.get(requirement.name)}
        id={`requirement${index}_input`}
        className={classes.inputField}
        variant="standard"
        color="secondary"
        fullWidth
        label={<FieldLabel requirement={requirement} />}
        helperText={requirement.description}
        value={inputsMap.get(requirement.name)}
        multiline
        rows={4}
        onChange={(event) => {
          const value = event.target.value;
          inputsMap.set(requirement.name, value);
          setInputsMap(new Map(inputsMap));
          setHasBeenModified(true);
        }}
        FormHelperTextProps={{
          sx: { '&.Mui-disabled': { color: lightTheme.palette.common.grayDark } },
        }}
      />
    </ListItem>
  );
};

export default InputTextArea;
