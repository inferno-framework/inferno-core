import React, { FC } from 'react';
import { AppBar, Box, Button, IconButton, Toolbar, Typography } from '@mui/material';
import { useHistory } from 'react-router-dom';
import { Menu, NoteAdd } from '@mui/icons-material';
import { getStaticPath } from '~/api/infernoApiService';
import { SuiteOptionChoice } from '~/models/testSuiteModels';
import { useAppStore } from '~/store/app';
import useStyles from './styles';
import icon from '~/images/inferno_icon.png';

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
  const windowIsSmall = useAppStore((state) => state.windowIsSmall);

  const returnHome = () => {
    history.push('/');
  };

  const suiteOptionsString =
    suiteOptions && suiteOptions.length > 0
      ? ` - ${suiteOptions.map((option) => option.label).join(', ')}`
      : '';

  return suiteTitle ? (
    <AppBar color="default" className={styles.appbar}>
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
        <Box display="flex" flexGrow="1" overflow="hidden">
          <Box
            display="flex"
            alignItems="baseline"
            alignSelf="center"
            overflow="auto"
            pt={0.5}
            tabIndex={0}
          >
            <Typography variant="h5" component="h1" className={styles.title}>
              {suiteTitle}
              {suiteOptionsString}
            </Typography>
            {suiteVersion && (
              <Typography variant="overline" className={styles.version}>
                {`v.${suiteVersion}`}
              </Typography>
            )}
          </Box>
        </Box>

        <Box display="flex" minWidth="fit-content" pl={2}>
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
        </Box>
      </Toolbar>
    </AppBar>
  ) : (
    <></>
  );
};

export default Header;
