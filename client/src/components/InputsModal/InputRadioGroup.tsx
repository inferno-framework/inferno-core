import React, { FC, useEffect } from 'react';
import {
  FormControl,
  FormControlLabel,
  FormLabel,
  ListItem,
  Radio,
  RadioGroup,
} from '@mui/material';
import Markdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { TestInput } from '~/models/testSuiteModels';
import FieldLabel from './FieldLabel';
import useStyles from './styles';

export interface InputRadioGroupProps {
  input: TestInput;
  index: number;
  inputsMap: Map<string, unknown>;
  setInputsMap: (map: Map<string, unknown>, edited?: boolean) => void;
}

const InputRadioGroup: FC<InputRadioGroupProps> = ({ input, index, inputsMap, setInputsMap }) => {
  const { classes } = useStyles();
  const firstOptionValue =
    input.options?.list_options && input.options?.list_options?.length > 0
      ? input.options?.list_options[0]?.value
      : '';

  // Set starting value to first option if no value and no default
  useEffect(() => {
    const startingValue =
      (inputsMap.get(input.name) as string) || (input.default as string) || firstOptionValue;
    inputsMap.set(input.name, startingValue);
    setInputsMap(new Map(inputsMap));
  }, []);

  return (
    <ListItem>
      <FormControl
        component="fieldset"
        id={`input${index}_control`}
        disabled={input.locked}
        fullWidth
        className={classes.inputField}
      >
        <FormLabel className={classes.inputLabel}>
          <FieldLabel input={input} />
        </FormLabel>
        {input.description && (
          <Markdown className={classes.inputDescription} remarkPlugins={[remarkGfm]}>
            {input.description}
          </Markdown>
        )}
        <RadioGroup
          row
          aria-label={`${input.name}-radio-buttons-group`}
          name={`${input.name}-radio-buttons-group`}
          value={inputsMap.get(input.name) || (input.default as string) || firstOptionValue}
          onChange={(event) => {
            inputsMap.set(input.name, event.target.value);
            setInputsMap(new Map(inputsMap));
          }}
        >
          {input.options?.list_options?.map((option, i) => (
            <FormControlLabel
              value={option.value}
              control={<Radio size="small" color="secondary" />}
              label={option.label}
              key={`radio-button-${i}`}
            />
          ))}
        </RadioGroup>
      </FormControl>
    </ListItem>
  );
};

export default InputRadioGroup;
