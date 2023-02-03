import React, { FC } from 'react';
import { IconButton } from '@mui/material';
import { Close } from '@mui/icons-material';
import { useSnackbar } from 'notistack';

type Id = string | number | undefined;

interface CloseSnackbarProps {
  id: Id;
}

const CloseButton: FC<CloseSnackbarProps> = ({ id }) => {
  const { closeSnackbar } = useSnackbar();
  return (
    <IconButton aria-label="Close notification" color="inherit" onClick={() => closeSnackbar(id)}>
      <Close fontSize="small" />
    </IconButton>
  );
};

export default CloseButton;
