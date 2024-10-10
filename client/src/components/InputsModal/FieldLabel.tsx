import React, { FC } from 'react';
import LockIcon from '@mui/icons-material/Lock';
import { TestInput } from '~/models/testSuiteModels';
import useStyles from './styles';
import RequiredInputWarning from './RequiredInputWarning';

export interface FieldLabelProps {
  requirement: TestInput;
  isMissingInput?: boolean;
}

const FieldLabel: FC<FieldLabelProps> = ({ requirement, isMissingInput = false }) => {
  const { classes } = useStyles();

  const fieldLabelText = (requirement.title || requirement.name) as string;

  // Radio buttons and single checkboxes will always have an input value
  const requiredLabel =
    !requirement.optional &&
    requirement.type !== 'radio' &&
    !(requirement.type === 'checkbox' && !requirement.options?.list_options?.length)
      ? ' (required)'
      : '';

  const lockedIcon = requirement.locked && (
    <LockIcon fontSize="small" className={classes.lockedIcon} />
  );

  return (
    <>
      {isMissingInput && <RequiredInputWarning />}
      {`${fieldLabelText}${requiredLabel}`}
      {lockedIcon}
    </>
  );
};

export default FieldLabel;
