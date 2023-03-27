import React, { FC } from 'react';
import LockIcon from '@mui/icons-material/Lock';
import { TestInput } from '~/models/testSuiteModels';
import useStyles from './styles';

export interface FieldLabelProps {
  requirement: TestInput;
}

const FieldLabel: FC<FieldLabelProps> = ({ requirement }) => {
  const { classes } = useStyles();

  const fieldLabelText = requirement.title || requirement.name;

  const requiredLabel = !requirement.optional ? ' (required)' : '';

  const lockedIcon = requirement.locked && (
    <LockIcon fontSize="small" className={classes.lockedIcon} />
  );

  return (
    <>
      {fieldLabelText}
      {requiredLabel}
      {lockedIcon}
    </>
  );
};

export default FieldLabel;
