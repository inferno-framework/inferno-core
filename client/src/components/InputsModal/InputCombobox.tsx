import React, { FC } from 'react';
import { Autocomplete, FormControl, FormLabel, Input, ListItem, Typography } from '@mui/material';
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
          <Typography variant="subtitle1" className={classes.inputDescription}>
            {requirement.description}
          </Typography>
        )}

        <Autocomplete
          options={[
            { label: 'Public', value: 'public' },
            { label: 'Confidential Symmetric', value: 'symmetric' },
            { label: 'Confidential Asymmetric', value: 'asymmetric' },
            { label: 'Backend Services', value: 'backend_services' },
          ]}
          // defaultValue={requirement.}
          renderInput={(params) => (
            <Input
              {...params}
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
          )}
          color="secondary"
          fullWidth
        />
      </FormControl>
    </ListItem>
  );
};

export default InputCombobox;
