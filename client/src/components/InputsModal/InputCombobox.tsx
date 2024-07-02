import React, { FC } from 'react';
import {
  Autocomplete,
  FormControl,
  FormLabel,
  ListItem,
  TextField,
  Typography,
} from '@mui/material';
import { TestInput } from '~/models/testSuiteModels';
import FieldLabel from './FieldLabel';
import useStyles from './styles';

export interface InputComboboxProps {
  requirement: TestInput;
  index: number;
  inputsMap: Map<string, unknown>;
  setInputsMap: (map: Map<string, unknown>, edited?: boolean) => void;
}

const InputCombobox: FC<InputComboboxProps> = ({ requirement, index, inputsMap, setInputsMap }) => {
  const { classes } = useStyles();

  return (
    <ListItem>
      <FormControl
        component="fieldset"
        id={`requirement${index}_control`}
        disabled={requirement.locked}
        required={!requirement.optional}
        fullWidth
        className={classes.inputField}
      >
        <FormLabel htmlFor={`requirement${index}_input`} className={classes.inputLabel}>
          <FieldLabel requirement={requirement} />
        </FormLabel>
        {requirement.description && (
          <Typography variant="subtitle1" className={classes.inputDescription}>
            {requirement.description}
          </Typography>
        )}
        <Autocomplete
          options={requirement.options?.list_options || []}
          defaultValue={
            requirement.options?.list_options ? requirement.options?.list_options[0] : null
          }
          isOptionEqualToValue={(option, value) => {
            console.log(option, value);

            return option.value === value.value;
          }}
          renderInput={(params) => (
            <TextField
              {...params}
              disabled={requirement.locked}
              required={!requirement.optional}
              id={`requirement${index}_input`}
              className={classes.inputField}
              color="secondary"
              variant="standard"
              fullWidth
              multiline={requirement.type === 'textarea'}
              minRows={requirement.type === 'textarea' ? 4 : 1}
              maxRows={20}
              value={inputsMap.get(requirement.name)}
              onChange={(event) => {
                const value = event.target.value;
                inputsMap.set(requirement.name, value);
                setInputsMap(new Map(inputsMap));
              }}
            />
          )}
          color="secondary"
          fullWidth
        />
      </FormControl>
    </ListItem>
  );
};

export default InputCombobox;
