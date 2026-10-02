import React, { FC } from 'react';
import { Autocomplete, FormControl, FormLabel, ListItem, TextField } from '@mui/material';
import Markdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { InputOption, TestInput } from '~/models/testSuiteModels';
import FieldLabel from '~/components/InputsModal/FieldLabel';
import { useTestSessionStore } from '~/store/testSession';
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
  const readOnly = useTestSessionStore((state) => state.readOnly);

  // Resolves to the stored value in inputsMap, falling back to the input's
  // default, then the first option. Used as a controlled `value` (rather than
  // `defaultValue`) so a stored value is reflected even when inputsMap is
  // populated after this component has already mounted.
  //
  // inputsMap always holds a string for this input once the modal's seeding
  // effect has run (persisted session value, default, or ''); `undefined`
  // only occurs when the user has explicitly cleared the selection, so that
  // case is treated as "no selection" rather than falling back to a default.
  const getCurrentValue = (): InputOption | null => {
    const options = input.options?.list_options;
    if (!options) return null;

    if (inputsMap.has(input.name) && inputsMap.get(input.name) === undefined) {
      return null;
    }

    const storedValue = inputsMap.get(input.name);
    const preferredValue =
      typeof storedValue === 'string' && storedValue ? storedValue : input.default;

    if (preferredValue && typeof preferredValue === 'string') {
      const discoveredOption = options.find((option) => option.value === preferredValue);
      if (discoveredOption) return discoveredOption;
    }
    return options[0] ?? null; // fall back to first option if no stored/default value matches
  };

  return (
    <ListItem>
      <FormControl
        component="fieldset"
        id={`input${index}_control`}
        tabIndex={0}
        disabled={input.locked || readOnly}
        aria-disabled={input.locked || readOnly}
        required={!input.optional}
        fullWidth
        className={classes.inputField}
      >
        <FormLabel htmlFor={`input${index}_autocomplete`} className={classes.inputLabel}>
          <FieldLabel input={input} />
        </FormLabel>
        {input.description && (
          <Markdown className={classes.inputDescription} remarkPlugins={[remarkGfm]}>
            {input.description}
          </Markdown>
        )}
        <Autocomplete
          id={`input${index}_autocomplete`}
          options={input.options?.list_options || []}
          value={getCurrentValue()}
          tabIndex={0}
          disabled={input.locked || readOnly}
          aria-disabled={input.locked || readOnly}
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
