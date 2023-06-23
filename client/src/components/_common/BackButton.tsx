import React, { FC } from 'react';
import { IconButton, Tooltip } from '@mui/material';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import { useNavigate } from 'react-router-dom';

export interface BackButtonProps {
  tooltipText: string;
  destination: string;
}

const BackButton: FC<BackButtonProps> = ({ tooltipText, destination }) => {
  const navigate = useNavigate();

  return (
    <Tooltip title={tooltipText}>
      <IconButton size="small" onClick={() => navigate(destination)}>
        <ArrowBackIcon fontSize="large" />
      </IconButton>
    </Tooltip>
  );
};

export default BackButton;
