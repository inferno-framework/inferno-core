import React, { FC } from 'react';
import { Chip } from '@mui/material';
import infernoIcon from '~/images/inferno_icon.png';
import CustomTooltip from '~/components/_common/CustomTooltip';

import useStyles from './styles';

const SimulationVerificationBadge: FC = () => {
  const { classes } = useStyles();

  return (
    <CustomTooltip title="This test performs simulation verification">
      <Chip
        icon={<img src={infernoIcon} alt="Inferno" style={{ width: 18, height: 18 }} />}
        label="Simulation Verification"
        size="small"
        className={classes.simulationVerificationChip}
      />
    </CustomTooltip>
  );
};

export default SimulationVerificationBadge;
