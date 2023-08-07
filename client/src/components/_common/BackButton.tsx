import React, { FC } from 'react';
import { IconButton } from '@mui/material';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import CustomTooltip from '~/components/_common/CustomTooltip';

export interface BackButtonProps {
  tooltipText: string;
  clickHandler: () => void;
}

const BackButton: FC<BackButtonProps> = ({ tooltipText, clickHandler }) => {
  return (
    <CustomTooltip title={tooltipText}>
      <IconButton size="small" onClick={clickHandler}>
        <ArrowBackIcon fontSize="large" />
      </IconButton>
    </CustomTooltip>
  );
};

export default BackButton;
