import React, { FC, useEffect } from 'react';
import {
  Checkbox,
  FormControl,
  FormControlLabel,
  FormGroup,
  FormLabel,
  ListItem,
} from '@mui/material';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { CheckboxValues, TestInput } from '~/models/testSuiteModels';
import FieldLabel from './FieldLabel';
import useStyles from './styles';

export interface InputCheckboxGroupProps {
  input: TestInput;
  index: number;
  inputsMap: Map<string, unknown>;
  setInputsMap: (map: Map<string, unknown>, edited?: boolean) => void;
}

const InputCheckboxGroup: FC<InputCheckboxGroupProps> = ({
  input,
  index,
  inputsMap,
  setInputsMap,
}) => {
  const { classes } = useStyles();
  const [hasBeenModified, setHasBeenModified] = React.useState(false);

  const [values, setValues] = React.useState<CheckboxValues>(() => {
    // Default values should be in form ['value'] where all values are checked
    let inputMapValues: string[] = [];
    try {
      // Parse JSON string of values
      inputMapValues = JSON.parse(inputsMap.get(input.name) as string) as string[];
      // eslint-disable-next-line @typescript-eslint/no-unused-vars
    } catch (e) {
      // If not JSON string, then either array or single value
      if (Array.isArray(inputsMap.get(input.name))) {
        inputMapValues = inputsMap.get(input.name) as string[];
      } else {
        inputMapValues = [inputsMap.get(input.name) as string]; // expecting single value
      }
    }

    const defaultValues = inputMapValues || input.default || [];
    const options = input.options?.list_options;

    let startingValues = {};
    // Convert array of checked values to map from item name to checked status
    if (options && options.length > 0) {
      startingValues = options.reduce(
        (acc, option) => (
          (acc[option.value] = Array.isArray(defaultValues)
            ? defaultValues.includes(option.value)
            : false), // default to false if defaultValues is not an array of checked values
          acc
        ),
        {} as CheckboxValues,
      );
    }
    return startingValues as CheckboxValues;
  });

  const isMissingInput = hasBeenModified && !input.optional && inputsMap.get(input.name) === '[]';

  useEffect(() => {
    // Make sure starting values get set in inputsMap
    inputsMap.set(input.name, transformValuesToJSONArray(values));
    setInputsMap(new Map(inputsMap), false);
  }, []);

  const handleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const newValues = {
      ...values,
      [event.target.name]: event.target.checked,
    };
    inputsMap.set(input.name, transformValuesToJSONArray(newValues));
    setInputsMap(new Map(inputsMap));
    setValues(newValues);
    setHasBeenModified(true);
  };

  // Convert map from item name to checked status back to array of checked values
  const transformValuesToJSONArray = (values: CheckboxValues): string => {
    const checkedValues = Object.entries(values)
      .filter(([, value]) => value === true)
      .map(([key]) => key);

    // Stringify array before setting input map to prevent empty inputs setting default inputs
    return JSON.stringify(checkedValues);
  };

  return (
    <ListItem>
      <FormControl
        component="fieldset"
        id={`requirement${index}_input`}
        disabled={input.locked}
        required={!input.optional}
        error={isMissingInput}
        fullWidth
        className={classes.inputField}
      >
        <FormLabel className={classes.inputLabel}>
          <FieldLabel input={input} isMissingInput={isMissingInput} />
        </FormLabel>
        {input.description && (
          <ReactMarkdown className={classes.inputDescription} remarkPlugins={[remarkGfm]}>
            {input.description}
          </ReactMarkdown>
        )}
        <FormGroup aria-label={`${input.name}-checkboxes-group`}>
          {input.options?.list_options?.map((option, i) => (
            <FormControlLabel
              control={
                <Checkbox
                  size="small"
                  color="secondary"
                  name={option.value}
                  disabled={!!option.locked}
                  checked={values[option.value as keyof CheckboxValues] || false}
                  onBlur={(e) => {
                    if (e.currentTarget === e.target) {
                      setHasBeenModified(true);
                    }
                  }}
                  onChange={handleChange}
                />
              }
              label={option.label}
              key={`checkbox-${i}`}
            />
          ))}
        </FormGroup>
      </FormControl>
    </ListItem>
  );
};

export default InputCheckboxGroup;
