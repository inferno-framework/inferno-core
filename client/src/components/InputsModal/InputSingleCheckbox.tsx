import React, { FC, useEffect } from 'react';
import { Checkbox, FormControl, FormControlLabel, FormGroup, ListItem } from '@mui/material';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { TestInput } from '~/models/testSuiteModels';
import FieldLabel from '~/components/InputsModal/FieldLabel';
import useStyles from '~/components/InputsModal/styles';

export interface InputSingleCheckboxProps {
  input: TestInput;
  index: number;
  inputsMap: Map<string, unknown>;
  setInputsMap: (map: Map<string, unknown>, edited?: boolean) => void;
}

const InputSingleCheckbox: FC<InputSingleCheckboxProps> = ({
  input,
  index,
  inputsMap,
  setInputsMap,
}) => {
  const { classes } = useStyles();
  const [hasBeenModified, setHasBeenModified] = React.useState(false);
  const [value, setValue] = React.useState<boolean>(false);

  const isMissingInput = hasBeenModified && !input.optional && inputsMap.get(input.name) === false;

  // No "required" formatting because single checkboxes always have a value assigned
  const fieldLabel = <FieldLabel input={input} isMissingInput={isMissingInput} />;

  useEffect(() => {
    const inputsValue = inputsMap.get(input.name) as string;
    let startingValue = false;
    if (inputsValue === 'true') {
      startingValue = true;
    } else if (inputsValue !== 'false' && (input.default as string) === 'true') {
      startingValue = true;
    }
    setValue(startingValue);
  }, []);

  const handleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const newValue = event.target.checked;
    setValue(newValue);
    setHasBeenModified(true);
    inputsMap.set(input.name, newValue.toString());
    setInputsMap(new Map(inputsMap));
  };

  return (
    <ListItem>
      <FormControl
        component="fieldset"
        id={`input${index}_control`}
        disabled={input.locked}
        required={!input.optional}
        error={isMissingInput}
        fullWidth
        className={classes.inputField}
      >
        {input.description && (
          <ReactMarkdown className={classes.inputDescription} remarkPlugins={[remarkGfm]}>
            {input.description}
          </ReactMarkdown>
        )}
        {/* TODO: required means set to true and locked? */}
        <FormGroup aria-label={`${input.name}-single-checkbox`}>
          <FormControlLabel
            control={
              <Checkbox
                size="small"
                color="secondary"
                checked={value}
                onBlur={(e) => {
                  if (e.currentTarget === e.target) {
                    setHasBeenModified(true);
                  }
                }}
                onChange={handleChange}
              />
            }
            label={fieldLabel}
            key={`checkbox-${input.name}`}
          />
        </FormGroup>
      </FormControl>
    </ListItem>
  );
};

export default InputSingleCheckbox;
