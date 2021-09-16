import { Tooltip } from '@material-ui/core';
import React, { FC } from 'react';
import WarningIcon from '@material-ui/icons/Warning';

const RequiredInputWarning: FC = () => {
  return (
    <Tooltip title="Missing value for required input">
      <WarningIcon />
    </Tooltip>
  );
};

export default RequiredInputWarning;
