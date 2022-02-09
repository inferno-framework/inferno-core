import React, { FC } from 'react';
import useStyles from './styles';
import icon from 'images/inferno_icon.png';
import { AppBar, Box, Button, Container, Toolbar, Typography } from '@mui/material';
import { useHistory } from 'react-router-dom';
import NoteAddIcon from '@mui/icons-material/NoteAdd';

export interface HeaderProps {
  suiteTitle?: string;
}

const Header: FC<HeaderProps> = ({ suiteTitle }) => {
  const styles = useStyles();
  const history = useHistory();

  const returnHome = () => {
    history.push('/');
  };

  return suiteTitle ? (
    <AppBar position="sticky" color="default" className={styles.appbar}>
      <Toolbar className={styles.toolbar}>
        <Box display="flex" justifyContent="center">
          <a href="/" onClick={returnHome}>
            <img
              src={icon as string}
              alt="inferno logo"
              className={styles.logo}
              onClick={returnHome}
            />
          </a>
          <Typography variant="h5" component="h1" className={styles.title}>
            {suiteTitle}
          </Typography>
        </Box>
        <Box>
          <Button
            color="secondary"
            onClick={returnHome}
            variant="outlined"
            disableElevation
            size="small"
            startIcon={<NoteAddIcon />}
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
