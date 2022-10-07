import React, { FC } from 'react';
import useStyles from './styles';
import icon from '~/images/inferno_icon.png';
import { AppBar, Box, Button, IconButton, Toolbar, Typography } from '@mui/material';
import { useHistory } from 'react-router-dom';
import NoteAddIcon from '@mui/icons-material/NoteAdd';
import { getStaticPath } from '~/api/infernoApiService';
import { SuiteOptionChoice } from '~/models/testSuiteModels';

import { useAppStore } from '~/store/app';
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
  const windowIsSmall = useAppStore((state) => state.windowIsSmall);

  const returnHome = () => {
    history.push('/');
  };

  const suiteOptionsString =
    suiteOptions && suiteOptions.length > 0
      ? `${suiteOptions.map((option) => option.label).join(', ')}`
      : '';

  return suiteTitle ? (
    <AppBar color="default" className={styles.appbar}>
      <Toolbar className={styles.toolbar}>
        <Box display="flex" overflow="hidden">
          <IconButton
            size="small"
            edge="start"
            aria-label="menu"
            disabled={!windowIsSmall}
            onClick={() => toggleDrawer(!drawerOpen)}
          >
            <img src={getStaticPath(icon as string)} alt="Inferno logo" className={styles.logo} />
          </IconButton>
          <Box alignSelf="center" overflow="auto" py={0.5} tabIndex={0}>
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
            <Typography
              variant="subtitle2"
              component="h2"
              className={styles.title}
              color={lightTheme.palette.common.gray}
            >
              {suiteOptionsString}
            </Typography>
          </Box>
        </Box>
        <Box display="flex" minWidth="fit-content" pl={2}>
          <Button
            disableElevation
            color="secondary"
            size="small"
            variant="contained"
            startIcon={<NoteAddIcon />}
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
