import { Tooltip } from '@mui/material';
import React, { FC } from 'react';
import WarningIcon from '@mui/icons-material/Warning';

const RequiredInputWarning: FC = () => {
  return (
    <Tooltip title="Missing value for required input">
      <WarningIcon />
    </Tooltip>
  );
};

export default RequiredInputWarning;
