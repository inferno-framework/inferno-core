import React, { FC } from 'react';
import {
  Autocomplete,
  FormControl,
  FormLabel,
  ListItem,
  TextField,
  Typography,
} from '@mui/material';
import { InputOption, TestInput } from '~/models/testSuiteModels';
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

  const getDefaultValue = (): InputOption | null => {
    const options = requirement.options?.list_options;
    if (!options) return null;

    let defaultValue = options[0]; // set to first option if no default provided
    if (requirement.default && typeof requirement.default === 'string') {
      const discoveredOption = options.find((option) => option.value === requirement.default);
      if (discoveredOption) defaultValue = discoveredOption;
    }
    return defaultValue;
  };

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
          <Typography variant="subtitle1" component="p" className={classes.inputDescription}>
            {requirement.description}
          </Typography>
        )}
        <Autocomplete
          id={`requirement${index}_input`}
          options={requirement.options?.list_options || []}
          defaultValue={getDefaultValue()}
          disabled={requirement.locked}
          isOptionEqualToValue={(option, value) => option.value === value.value}
          renderInput={(params) => (
            <TextField
              {...params}
              className={classes.inputField}
              required={!requirement.optional}
              color="secondary"
              variant="standard"
              fullWidth
            />
          )}
          onChange={(event, newValue: InputOption | null) => {
            const value = newValue?.value;
            inputsMap.set(requirement.name, value);
            setInputsMap(new Map(inputsMap));
          }}
        />
      </FormControl>
    </ListItem>
  );
};

export default InputCombobox;
