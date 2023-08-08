import React, { FC } from 'react';
import WarningIcon from '@mui/icons-material/Warning';
import CustomTooltip from '~/components/_common/CustomTooltip';

const RequiredInputWarning: FC = () => {
  return (
    <CustomTooltip title="Missing value for required input">
      <WarningIcon fontSize="small" color="error" />
    </CustomTooltip>
  );
};

export default RequiredInputWarning;
