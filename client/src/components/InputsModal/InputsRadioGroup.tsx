import {
  FormControl,
  FormControlLabel,
  InputLabel,
  ListItem,
  Radio,
  RadioGroup,
} from '@mui/material';
import LockIcon from '@mui/icons-material/Lock';
import { TestInput } from 'models/testSuiteModels';
import React, { FC, Fragment } from 'react';
import useStyles from './styles';

export interface InputRadioGroupProps {
  requirement: TestInput;
  index: number;
  inputsMap: Map<string, string>;
  setInputsMap: (map: Map<string, string>) => void;
}

const InputRadioGroup: FC<InputRadioGroupProps> = ({
  requirement,
  index,
  inputsMap,
  setInputsMap,
}) => {
  const styles = useStyles();
  const [value, setValue] = React.useState(
    inputsMap.get(requirement.name) || requirement.default || null
  );
  const fieldLabelText = requirement.title || requirement.name;
  const lockedIcon = requirement.locked && (
    <LockIcon fontSize="small" className={styles.lockedIcon} />
  );
  const requiredLabel = !requirement.optional && !requirement.locked ? ' (required)' : '';
  const fieldLabel = (
    <Fragment>
      {fieldLabelText}
      {requiredLabel}
      {lockedIcon}
    </Fragment>
  );

  const handleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const value = event.target.value;
    setValue(value);
    inputsMap.set(requirement.name, value);
    setInputsMap(new Map(inputsMap));
  };

  return (
    <ListItem disabled={requirement.locked}>
      <FormControl
        component="fieldset"
        id={`requirement${index}_input`}
        required={!requirement.optional && !requirement.locked}
        disabled={requirement.locked}
        fullWidth
      >
        <InputLabel variant="standard" shrink className={styles.inputLabel}>
          {fieldLabel}
        </InputLabel>
        <RadioGroup
          row
          aria-label={`${requirement.name}-radio-buttons-group`}
          name={`${requirement.name}-radio-buttons-group`}
          className={styles.radioGroup}
          value={value}
          onChange={handleChange}
        >
          {requirement.options?.list_options?.map((option, i) => (
            <FormControlLabel
              value={option.value}
              control={<Radio size="small" />}
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
