import React, { FC } from 'react';
import { AppBar, Avatar, Box, Button, IconButton, Link, Toolbar, Typography } from '@mui/material';
import { Link as RouterLink } from 'react-router-dom';
import { Menu, NoteAdd } from '@mui/icons-material';
import { basePath, getStaticPath } from '~/api/infernoApiService';
import { SuiteOptionChoice } from '~/models/testSuiteModels';
import { useAppStore } from '~/store/app';
import useStyles from './styles';
import icon from '~/images/inferno_icon.png';
import lightTheme from '~/styles/theme';
import CustomTooltip from '~/components/_common/CustomTooltip';
import HelpModal from '~/components/Header/HelpModal';
import ShareSessionButton from '~/components/Header/ShareSessionButton';
import HeaderSkeleton from '~/components/Skeletons/HeaderSkeleton';
import { useTestSessionStore } from '~/store/testSession';

export interface HeaderProps {
  suiteId?: string;
  suiteTitle?: string;
  suiteVersion?: string;
  suiteOptions?: SuiteOptionChoice[];
  drawerOpen: boolean;
  toggleDrawer: (drawerOpen: boolean) => void;
}

const Header: FC<HeaderProps> = ({
  suiteId,
  suiteTitle,
  suiteVersion,
  suiteOptions,
  drawerOpen,
  toggleDrawer,
}) => {
  const { classes } = useStyles();
  const headerHeight = useAppStore((state) => state.headerHeight);
  const windowIsSmall = useAppStore((state) => state.windowIsSmall);
  const viewOnly = useTestSessionStore((state) => state.viewOnly);
  const [showHelpModal, setShowHelpModal] = React.useState(false);

  // Use window navigation instead of React router to trigger new page request
  const startNewSession = () => {
    window.location.href = `/${basePath}`;
  };

  const suiteOptionsString =
    suiteOptions && suiteOptions.length > 0
      ? `${suiteOptions.map((option) => option.label).join(', ')}`
      : '';

  return suiteTitle ? (
    <AppBar
      color="default"
      className={classes.appbar}
      style={{
        minHeight: `${headerHeight}px`, // For responsive screens
        maxHeight: `${headerHeight}px`, // For responsive screens
      }}
    >
      <Toolbar className={classes.toolbar}>
        {/* Home button */}
        {windowIsSmall ? (
          <IconButton
            size="large"
            edge="start"
            color="secondary"
            aria-label="menu"
            onClick={() => toggleDrawer(!drawerOpen)}
          >
            <Menu fontSize="inherit" />
          </IconButton>
        ) : (
          <RouterLink to="/" reloadDocument aria-label="Inferno Home">
            <CustomTooltip title="Return to Suite Selection">
              <img
                src={getStaticPath(icon as string)}
                alt="Inferno logo"
                className={classes.logo}
              />
            </CustomTooltip>
          </RouterLink>
        )}

        {/* Header Text */}
        <Box
          display="flex"
          flexDirection="column"
          flexGrow="1"
          alignSelf="center"
          overflow="auto"
          py={0.5}
          tabIndex={0}
        >
          <Box display="flex" flexDirection="row" alignItems="baseline">
            <Typography variant="h5" component="h1" className={classes.title}>
              <RouterLink
                to={`/${suiteId || ''}`}
                reloadDocument
                aria-label="Inferno Home"
                className={classes.homeLink}
              >
                {suiteTitle}
              </RouterLink>
            </Typography>
            {suiteVersion && (
              <Typography variant="overline" className={classes.version}>
                {`v.${suiteVersion}`}
                {viewOnly ? ' (Read-Only Mode)' : ''}
              </Typography>
            )}
          </Box>
          {suiteOptionsString && (
            <Typography variant="subtitle2" component="h2" className={classes.title}>
              {suiteOptionsString}
            </Typography>
          )}
        </Box>

        {/* Share Session button */}
        <ShareSessionButton />

        {/* New Session button */}
        <Box
          display="flex"
          minWidth="fit-content"
          pl={1}
          style={windowIsSmall ? { marginRight: '-8px' } : {}}
        >
          {windowIsSmall ? (
            <IconButton color="secondary" aria-label="New Session" onClick={startNewSession}>
              <Avatar sx={{ width: 32, height: 32, bgcolor: lightTheme.palette.secondary.main }}>
                <NoteAdd fontSize="small" />
              </Avatar>
            </IconButton>
          ) : (
            <Button
              disableElevation
              color="secondary"
              size="small"
              variant="contained"
              startIcon={<NoteAdd />}
              onClick={startNewSession}
            >
              New Session
            </Button>
          )}
        </Box>

        {/* Help button */}
        <Box display="flex" minWidth="fit-content" pl={1}>
          <Link
            color="secondary"
            className={classes.help}
            style={windowIsSmall ? { fontSize: '0.8rem' } : { margin: '0 8px' }}
            onClick={() => setShowHelpModal(true)}
          >
            Help
          </Link>
        </Box>
        <HelpModal modalVisible={showHelpModal} hideModal={() => setShowHelpModal(false)} />
      </Toolbar>
    </AppBar>
  ) : (
    <HeaderSkeleton />
  );
};

export default Header;
