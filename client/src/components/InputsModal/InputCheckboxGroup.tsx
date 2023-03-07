import React, { FC, Fragment } from 'react';
import {
  Checkbox,
  FormControl,
  FormControlLabel,
  FormGroup,
  FormLabel,
  ListItem,
} from '@mui/material';
import LockIcon from '@mui/icons-material/Lock';
import { TestInput } from '~/models/testSuiteModels';
import useStyles from './styles';

export interface InputCheckboxGroupProps {
  requirement: TestInput;
  index: number;
  inputsMap: Map<string, unknown>;
  setInputsMap: (map: Map<string, unknown>) => void;
}

export interface CheckboxValuesProps {
  [key: string]: boolean;
}

const InputCheckboxGroup: FC<InputCheckboxGroupProps> = ({
  requirement,
  index,
  inputsMap,
  setInputsMap,
}) => {
  const styles = useStyles();

  const [values, setValues] = React.useState<CheckboxValuesProps>(
    (inputsMap.get(requirement.name) || requirement.default || {}) as CheckboxValuesProps
  );

  const fieldLabelText = requirement.title || requirement.name;

  const lockedIcon = requirement.locked && (
    <LockIcon fontSize="small" className={styles.lockedIcon} />
  );

  const fieldLabel = (
    <Fragment>
      {fieldLabelText}
      {lockedIcon}
    </Fragment>
  );

  const handleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setValues({
      ...values,
      [event.target.name]: event.target.checked,
    });
    inputsMap.set(requirement.name, values);
    setInputsMap(new Map(inputsMap));
  };

  return (
    <ListItem>
      <FormControl
        component="fieldset"
        id={`requirement${index}_input`}
        disabled={requirement.locked}
        fullWidth
      >
        <FormLabel className={styles.inputLabel}>{fieldLabel}</FormLabel>
        <FormGroup aria-label={`${requirement.name}-checkboxes-group`}>
          {requirement.options?.list_options?.map((option, i) => (
            <FormControlLabel
              control={
                <Checkbox
                  size="small"
                  name={option.value}
                  checked={values[option.value as keyof CheckboxValuesProps] || false}
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
