import React, { FC } from 'react';
import { Chip } from '@mui/material';
import PersonIcon from '@mui/icons-material/Person';
import CustomTooltip from '~/components/_common/CustomTooltip';

import useStyles from './styles';

const AttestationBadge: FC = () => {
  const { classes } = useStyles();

  return (
    <CustomTooltip title="Inferno cannot independently verify this behavior.">
      <Chip
        icon={<PersonIcon />}
        label="Attestation"
        size="small"
        className={classes.attestationChip}
      />
    </CustomTooltip>
  );
};

export default AttestationBadge;
