import React, { FC } from 'react';
import LockIcon from '@mui/icons-material/Lock';
import { TestInput } from '~/models/testSuiteModels';
import useStyles from './styles';
import RequiredInputWarning from './RequiredInputWarning';

export interface FieldLabelProps {
  input: TestInput;
  isMissingInput?: boolean;
}

const FieldLabel: FC<FieldLabelProps> = ({ input, isMissingInput = false }) => {
  const { classes } = useStyles();

  const fieldLabelText = (input.title || input.name) as string;

  // Radio buttons and single checkboxes will always have an input value
  const requiredLabel =
    !input.optional &&
    input.type !== 'radio' &&
    !(input.type === 'checkbox' && !input.options?.list_options?.length)
      ? ' (required)'
      : '';

  const lockedIcon = input.locked && <LockIcon fontSize="small" className={classes.lockedIcon} />;

  return (
    <>
      {isMissingInput && <RequiredInputWarning />}
      {`${fieldLabelText}${requiredLabel}`}
      {lockedIcon}
    </>
  );
};

export default FieldLabel;
