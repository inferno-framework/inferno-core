import React, { FC } from 'react';
import { AppBar, Avatar, Box, Button, IconButton, Toolbar, Typography } from '@mui/material';
import { useHistory } from 'react-router-dom';
import { Menu, NoteAdd } from '@mui/icons-material';
import { getStaticPath } from '~/api/infernoApiService';
import { SuiteOptionChoice } from '~/models/testSuiteModels';
import { useAppStore } from '~/store/app';
import useStyles from './styles';
import icon from '~/images/inferno_icon.png';
import lightTheme from '~/styles/theme';

export interface HeaderProps {
  suiteTitle?: string;
  suiteVersion?: string;
  suiteOptions?: SuiteOptionChoice[];
  drawerOpen: boolean;
  toggleDrawer: (drawerOpen: boolean) => void;
}

const Header: FC<HeaderProps> = ({
  suiteTitle,
  suiteVersion,
  suiteOptions,
  drawerOpen,
  toggleDrawer,
}) => {
  const styles = useStyles();
  const history = useHistory();
  const headerHeight = useAppStore((state) => state.headerHeight);
  const windowIsSmall = useAppStore((state) => state.windowIsSmall);

  const returnHome = () => {
    history.push('/');
  };

  const suiteOptionsString =
    suiteOptions && suiteOptions.length > 0
      ? `${suiteOptions.map((option) => option.label).join(', ')}`
      : '';

  return suiteTitle ? (
    <AppBar
      color="default"
      className={styles.appbar}
      style={{
        minHeight: `${headerHeight}px`, // For responsive screens
        maxHeight: `${headerHeight}px`, // For responsive screens
      }}
    >
      <Toolbar className={styles.toolbar}>
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
          <img src={getStaticPath(icon as string)} alt="Inferno logo" className={styles.logo} />
        )}
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
            <Typography
              variant="h5"
              component="h1"
              className={styles.title}
              color={lightTheme.palette.common.orangeDarker}
            >
              {suiteTitle}
            </Typography>
            {suiteVersion && (
              <Typography variant="overline" className={styles.version}>
                {`v.${suiteVersion}`}
              </Typography>
            )}
          </Box>
          {suiteOptionsString && (
            <Typography
              variant="subtitle2"
              component="h2"
              className={styles.title}
              color={lightTheme.palette.common.gray}
            >
              {suiteOptionsString}
            </Typography>
          )}
        </Box>

        <Box display="flex" minWidth="fit-content" pl={2}>
          {windowIsSmall ? (
            <IconButton color="secondary" aria-label="New Session" onClick={returnHome}>
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
              onClick={returnHome}
            >
              New Session
            </Button>
          )}
        </Box>
      </Toolbar>
    </AppBar>
  ) : (
    <></>
  );
};

export default Header;
