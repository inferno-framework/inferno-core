import React, { FC } from 'react';
import { Container, Link, ListItem, Typography } from '@mui/material';
import NotificationsIcon from '@mui/icons-material/Notifications';

const MessagesButton: FC = () => {
  return (
    <ListItem sx={{ display: 'flex', alignItems: 'flex-end' }}>
      <Link href="#/config" variant="body2" underline="hover">
        <NotificationsIcon />
        Configuration Messages
      </Link>
    </ListItem>
  );
};

export default MessagesButton;
