import React, { FC } from 'react';
import {
  Avatar,
  Box,
  Button,
  IconButton,
  ListItemIcon,
  ListItemText,
  Menu,
  MenuItem,
} from '@mui/material';
import { EditOff, Link, Share } from '@mui/icons-material';
import { useSnackbar } from 'notistack';
import { useAppStore } from '~/store/app';
// import useStyles from './styles';
import lightTheme from '~/styles/theme';

const ShareSessionButton: FC<unknown> = () => {
  // const { classes } = useStyles();
  const { enqueueSnackbar } = useSnackbar();
  const windowIsSmall = useAppStore((state) => state.windowIsSmall);
  const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);
  const [copySuccess, setCopySuccess] = React.useState({});
  const openShareMenu = Boolean(anchorEl);

  const handleShareClick = (event: React.MouseEvent<HTMLButtonElement>) => {
    setAnchorEl(event.currentTarget);
  };

  const copyLink = (readOnly?: boolean) => {
    handleMenuClose();
    const link = `${window.location.href}${readOnly && '/view'}`;
    void navigator.clipboard
      .writeText(link)
      .then(() => {
        setCopySuccess({ ...copySuccess, [link]: true });
        enqueueSnackbar(`Successfully copied ${readOnly && 'read-only '}session link`, {
          variant: 'success',
        });
        setTimeout(() => {
          // Reset map instead of setting false to avoid async bug
          setCopySuccess({});
        }, 2000); // 2 second delay
      })
      .catch((e) => {
        enqueueSnackbar(`Failed to copy session link: ${e}`, { variant: 'error' });
      });
  };

  const handleMenuClose = () => {
    setAnchorEl(null);
  };

  return (
    <Box display="flex" minWidth="fit-content" pl={1} sx={windowIsSmall ? { mr: -2 } : {}}>
      {/* Open menu button */}
      {windowIsSmall ? (
        <IconButton
          id="share-button"
          color="secondary"
          aria-label="Share Session"
          aria-controls={openShareMenu ? 'share-menu' : undefined}
          aria-haspopup="true"
          aria-expanded={openShareMenu ? 'true' : undefined}
          onClick={handleShareClick}
        >
          <Avatar sx={{ width: 32, height: 32, bgcolor: lightTheme.palette.secondary.main }}>
            <Share fontSize="small" />
          </Avatar>
        </IconButton>
      ) : (
        <Button
          id="share-button"
          disableElevation
          color="secondary"
          size="small"
          variant="text"
          startIcon={<Share />}
          aria-controls={openShareMenu ? 'share-menu' : undefined}
          aria-haspopup="true"
          aria-expanded={openShareMenu ? 'true' : undefined}
          onClick={handleShareClick}
        >
          Share Session
        </Button>
      )}

      {/* Share options menu */}
      <Menu
        id="share-menu"
        anchorEl={anchorEl}
        open={openShareMenu}
        onClose={handleMenuClose}
        MenuListProps={{
          dense: true,
          'aria-labelledby': 'share-button',
        }}
      >
        <MenuItem onClick={() => copyLink()}>
          <ListItemIcon>
            <Link fontSize="small" />
          </ListItemIcon>
          <ListItemText>Copy Session Link</ListItemText>
        </MenuItem>
        <MenuItem onClick={() => copyLink(true)}>
          <ListItemIcon>
            <EditOff fontSize="small" />
          </ListItemIcon>
          <ListItemText>Copy Read-Only Session Link</ListItemText>
        </MenuItem>
      </Menu>
    </Box>
  );
};

export default ShareSessionButton;
