import React, { FC } from 'react';
import { Autocomplete, FormControl, FormLabel, ListItem, TextField } from '@mui/material';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { InputOption, TestInput } from '~/models/testSuiteModels';
import FieldLabel from './FieldLabel';
import useStyles from './styles';

export interface InputComboboxProps {
  input: TestInput;
  index: number;
  inputsMap: Map<string, unknown>;
  setInputsMap: (map: Map<string, unknown>, edited?: boolean) => void;
  disableClear?: boolean;
}

const InputCombobox: FC<InputComboboxProps> = ({
  input,
  index,
  inputsMap,
  setInputsMap,
  disableClear,
}) => {
  const { classes } = useStyles();

  const getDefaultValue = (): InputOption | null => {
    const options = input.options?.list_options;
    if (!options) return null;

    let defaultValue = options[0]; // set to first option if no default provided
    if (input.default && typeof input.default === 'string') {
      const discoveredOption = options.find((option) => option.value === input.default);
      if (discoveredOption) defaultValue = discoveredOption;
    }
    return defaultValue;
  };

  return (
    <ListItem>
      <FormControl
        component="fieldset"
        id={`input${index}_control`}
        disabled={input.locked}
        required={!input.optional}
        fullWidth
        className={classes.inputField}
      >
        <FormLabel htmlFor={`input${index}_autocomplete`} className={classes.inputLabel}>
          <FieldLabel input={input} />
        </FormLabel>
        {input.description && (
          <ReactMarkdown className={classes.inputDescription} remarkPlugins={[remarkGfm]}>
            {input.description}
          </ReactMarkdown>
        )}
        <Autocomplete
          id={`input${index}_autocomplete`}
          options={input.options?.list_options || []}
          defaultValue={getDefaultValue()}
          disabled={input.locked}
          disableClearable={disableClear}
          isOptionEqualToValue={(option, value) => option.value === value.value}
          renderInput={(params) => (
            <TextField
              {...params}
              className={classes.inputField}
              required={!input.optional}
              color="secondary"
              variant="standard"
              fullWidth
            />
          )}
          onChange={(event, newValue: InputOption | null) => {
            const value = newValue?.value;
            inputsMap.set(input.name, value);
            setInputsMap(new Map(inputsMap));
          }}
        />
      </FormControl>
    </ListItem>
  );
};

export default InputCombobox;
