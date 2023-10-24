import React, { FC } from 'react';
import { IconButton } from '@mui/material';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import { useNavigate } from 'react-router-dom';
import CustomTooltip from '~/components/_common/CustomTooltip';

export interface BackButtonProps {
  tooltipText: string;
  destination: string;
}

const BackButton: FC<BackButtonProps> = ({ tooltipText, destination }) => {
  const navigate = useNavigate();

  return (
    <CustomTooltip title={tooltipText}>
      <IconButton size="small" onClick={() => navigate(destination)}>
        <ArrowBackIcon fontSize="large" />
      </IconButton>
    </CustomTooltip>
  );
};

export default BackButton;
