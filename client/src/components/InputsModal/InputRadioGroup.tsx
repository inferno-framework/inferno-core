import React, { FC, useEffect } from 'react';
import {
  FormControl,
  FormControlLabel,
  FormLabel,
  ListItem,
  Radio,
  RadioGroup,
  Typography,
} from '@mui/material';
import { TestInput } from '~/models/testSuiteModels';
import FieldLabel from './FieldLabel';
import useStyles from './styles';

export interface InputRadioGroupProps {
  requirement: TestInput;
  index: number;
  inputsMap: Map<string, unknown>;
  setInputsMap: (map: Map<string, unknown>, edited?: boolean) => void;
}

const InputRadioGroup: FC<InputRadioGroupProps> = ({
  requirement,
  index,
  inputsMap,
  setInputsMap,
}) => {
  const { classes } = useStyles();
  const firstValue =
    requirement.options?.list_options && requirement.options?.list_options?.length > 0
      ? requirement.options?.list_options[0]?.value
      : '';
  const [value, setValue] = React.useState(
    inputsMap.get(requirement.name) || requirement.default || firstValue
  );

  // Set default on mounted
  useEffect(() => {
    inputsMap.set(requirement.name, value);
    setInputsMap(new Map(inputsMap));
  }, []);

  const handleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const value = event.target.value;
    setValue(value);
    inputsMap.set(requirement.name, value);
    setInputsMap(new Map(inputsMap));
  };

  return (
    <ListItem>
      <FormControl
        component="fieldset"
        id={`requirement${index}_input`}
        disabled={requirement.locked}
        fullWidth
        className={classes.inputField}
      >
        <FormLabel required={!requirement.optional} className={classes.inputLabel}>
          <FieldLabel requirement={requirement} />
        </FormLabel>
        {requirement.description && (
          <Typography variant="subtitle1" className={classes.inputDescription}>
            {requirement.description}
          </Typography>
        )}
        <RadioGroup
          row
          aria-label={`${requirement.name}-radio-buttons-group`}
          name={`${requirement.name}-radio-buttons-group`}
          value={value}
          onChange={handleChange}
        >
          {requirement.options?.list_options?.map((option, i) => (
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
