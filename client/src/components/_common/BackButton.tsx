import React, { FC } from 'react';
import { IconButton, Tooltip } from '@mui/material';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';

export interface BackButtonProps {
  tooltipText: string;
  clickHandler: () => void;
}

const BackButton: FC<BackButtonProps> = ({ tooltipText, clickHandler }) => {
  return (
    <Tooltip title={tooltipText}>
      <IconButton size="small" onClick={clickHandler}>
        <ArrowBackIcon fontSize="large" />
      </IconButton>
    </Tooltip>
  );
};

export default BackButton;
