import React, { FC } from 'react';
import { Chip } from '@mui/material';
import SwapHorizIcon from '@mui/icons-material/SwapHoriz';
import CustomTooltip from '~/components/_common/CustomTooltip';

import useStyles from './styles';

const TesterInitiatedExchangeBadge: FC = () => {
  const { classes } = useStyles();

  return (
    <CustomTooltip title="Requires the system under test to send requests to Inferno.">
      <Chip
        icon={<SwapHorizIcon />}
        label="Tester-Initiated Exchange"
        size="small"
        className={classes.testerInitiatedExchangeChip}
      />
    </CustomTooltip>
  );
};

export default TesterInitiatedExchangeBadge;
