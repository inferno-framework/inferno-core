import { ListItem, TextField } from '@mui/material';
import LockIcon from '@mui/icons-material/Lock';
import { TestInput } from '~/models/testSuiteModels';
import React, { FC, Fragment } from 'react';
import useStyles from './styles';
import lightTheme from 'styles/theme';

export interface InputTextAreaProps {
  requirement: TestInput;
  index: number;
  inputsMap: Map<string, unknown>;
  setInputsMap: (map: Map<string, unknown>) => void;
}

const InputTextArea: FC<InputTextAreaProps> = ({ requirement, index, inputsMap, setInputsMap }) => {
  const { classes } = useStyles();
  const fieldLabelText = requirement.title || requirement.name;
  const lockedIcon = requirement.locked ? (
    <LockIcon fontSize="small" className={classes.lockedIcon} />
  ) : null;
  const requiredLabel = !requirement.optional ? ' (required)' : '';
  const fieldLabel = (
    <Fragment>
      {fieldLabelText}
      {requiredLabel}
      {lockedIcon}
    </Fragment>
  );

  return (
    <ListItem>
      <TextField
        disabled={requirement.locked}
        required={!requirement.optional}
        id={`requirement${index}_input`}
        className={classes.inputField}
        variant="standard"
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
        FormHelperTextProps={{
          sx: { '&.Mui-disabled': { color: lightTheme.palette.common.grayDark } },
        }}
      />
    </ListItem>
  );
};

export default InputTextArea;
