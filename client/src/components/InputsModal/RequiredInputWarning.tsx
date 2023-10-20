import React, { FC } from 'react';
import { Report } from '@mui/icons-material';
import CustomTooltip from '~/components/_common/CustomTooltip';

const RequiredInputWarning: FC = () => {
  return (
    <CustomTooltip title="Missing value for required input">
      <Report
        color="error"
        aria-hidden={false}
        tabIndex={0}
        sx={{
          marginRight: '4px',
          verticalAlign: 'bottom',
        }}
      />
    </CustomTooltip>
  );
};

export default RequiredInputWarning;
