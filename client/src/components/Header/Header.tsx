import React, { FC } from 'react';
import { AppBar, Avatar, Box, Button, IconButton, Toolbar, Typography } from '@mui/material';
import { Link, useHistory } from 'react-router-dom';
import { Menu, NoteAdd } from '@mui/icons-material';
import { getStaticPath } from '~/api/infernoApiService';
import { SuiteOptionChoice, TestSession } from '~/models/testSuiteModels';
import { useAppStore } from '~/store/app';
import useStyles from './styles';
import icon from '~/images/inferno_icon.png';
import lightTheme from '~/styles/theme';
import { postTestSessions } from '~/api/TestSessionApi';

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
  const styles = useStyles();
  const history = useHistory();
  const headerHeight = useAppStore((state) => state.headerHeight);
  const windowIsSmall = useAppStore((state) => state.windowIsSmall);
  const setTestSession = useAppStore((state) => state.setTestSession);

<<<<<<< Updated upstream
  const returnHome = () => {
    history.push('/');
=======
  const startNewSession = () => {
    if (!suiteId) {
      navigate('/');
    } else {
      postTestSessions(suiteId, null, null)
        .then((testSession: TestSession | null) => {
          navigate('/');

          if (testSession && testSession.test_suite) {
            setTestSession(testSession);
          }
        })
        .catch(() => {
          navigate('/');
        });
    }
>>>>>>> Stashed changes
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
          <Link to="/" aria-label="Inferno Home" onClick={() => setTestSession(undefined)}>
            <img src={getStaticPath(icon as string)} alt="Inferno logo" className={styles.logo} />
          </Link>
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
            <Typography variant="h5" component="h1" className={styles.title}>
              <Link to={`/${suiteId || ''}`} aria-label="Inferno Home" className={styles.homeLink}>
                {suiteTitle}
              </Link>
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

        {/* New Session button */}
        <Box
          display="flex"
          minWidth="fit-content"
          pl={1}
          style={windowIsSmall ? { marginRight: '-16px' } : {}}
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
      </Toolbar>
    </AppBar>
  ) : (
    <></>
  );
};

export default Header;
