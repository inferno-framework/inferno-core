import React, { FC } from 'react';
import { Chip } from '@mui/material';
import PersonIcon from '@mui/icons-material/Person';
import CustomTooltip from '~/components/_common/CustomTooltip';

import useStyles from './styles';

const SimulationVerificationBadge: FC = () => {
  const { classes } = useStyles();

  return (
    <CustomTooltip title="This test performs simulation verification">
      <Chip
        icon={<PersonIcon />}
        label="Simulation Verification"
        size="small"
        className={classes.simulationVerificationChip}
      />
    </CustomTooltip>
  );
};

export default SimulationVerificationBadge;
