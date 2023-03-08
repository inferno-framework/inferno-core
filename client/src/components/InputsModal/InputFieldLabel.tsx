import React, { FC } from 'react';
import LockIcon from '@mui/icons-material/Lock';
import { TestInput } from '~/models/testSuiteModels';
import useStyles from './styles';

export interface InputFieldLabelProps {
  requirement: TestInput;
}

const InputFieldLabel: FC<InputFieldLabelProps> = ({ requirement }) => {
  const styles = useStyles();

  const fieldLabelText = requirement.title || requirement.name;

  const lockedIcon = requirement.locked && (
    <LockIcon fontSize="small" className={styles.lockedIcon} />
  );

  return (
    <>
      {fieldLabelText}
      {lockedIcon}
    </>
  );
};

export default InputFieldLabel;
