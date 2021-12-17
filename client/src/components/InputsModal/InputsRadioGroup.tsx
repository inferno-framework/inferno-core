import {
  FormControl,
  FormControlLabel,
  FormLabel,
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

  return (
    <ListItem disabled={requirement.locked}>
      <FormControl component="fieldset">
        <FormLabel component="legend">{fieldLabel}</FormLabel>
        <RadioGroup row aria-label={requirement.name} name="radio-buttons-group">
          {requirement.inputOptions?.map((inputOption) => (
            <FormControlLabel
              value={inputOption.value}
              control={<Radio />}
              label={inputOption.label}
            />
          ))}
        </RadioGroup>
      </FormControl>
    </ListItem>
  );
};

export default InputRadioGroup;
