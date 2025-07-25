import React, { FC } from 'react';
import { FormControl, FormLabel, Input, ListItem } from '@mui/material';
import Markdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { TestInput } from '~/models/testSuiteModels';
import FieldLabel from '~/components/InputsModal/FieldLabel';
import { useTestSessionStore } from '~/store/testSession';
import useStyles from './styles';

export interface InputTextFieldProps {
  input: TestInput;
  index: number;
  inputsMap: Map<string, unknown>;
  setInputsMap: (map: Map<string, unknown>, edited?: boolean) => void;
}

const InputTextField: FC<InputTextFieldProps> = ({ input, index, inputsMap, setInputsMap }) => {
  const { classes } = useStyles();
  const readOnly = useTestSessionStore((state) => state.readOnly);
  const [hasBeenModified, setHasBeenModified] = React.useState(false);

  const isMissingInput = hasBeenModified && !input.optional && !inputsMap.get(input.name);

  return (
    <ListItem>
      <FormControl
        component="fieldset"
        id={`input${index}_control`}
        tabIndex={0}
        disabled={input.locked || readOnly}
        aria-disabled={input.locked || readOnly}
        required={!input.optional}
        error={isMissingInput}
        fullWidth
        className={classes.inputField}
      >
        <FormLabel htmlFor={`input${index}_text`} className={classes.inputLabel}>
          <FieldLabel input={input} isMissingInput={isMissingInput} />
        </FormLabel>
        {input.description && (
          <Markdown className={classes.inputDescription} remarkPlugins={[remarkGfm]}>
            {input.description}
          </Markdown>
        )}
        <Input
          tabIndex={0}
          disabled={input.locked || readOnly}
          aria-disabled={input.locked || readOnly}
          required={!input.optional}
          error={isMissingInput}
          id={`input${index}_text`}
          className={classes.inputField}
          color="secondary"
          fullWidth
          multiline={input.type === 'textarea'}
          minRows={input.type === 'textarea' ? 4 : 1}
          maxRows={20}
          value={inputsMap.get(input.name) || ''}
          onBlur={(e) => {
            if (e.currentTarget === e.target) {
              setHasBeenModified(true);
            }
          }}
          onChange={(event) => {
            const value = event.target.value;
            inputsMap.set(input.name, value);
            setInputsMap(new Map(inputsMap));
          }}
        />
      </FormControl>
    </ListItem>
  );
};

export default InputTextField;
