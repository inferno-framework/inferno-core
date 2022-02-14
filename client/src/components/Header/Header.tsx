import React, { FC } from 'react';
import useStyles from './styles';
import icon from 'images/inferno_icon.png';
import { AppBar, Box, Button, Container, Typography } from '@mui/material';
import { useHistory } from 'react-router-dom';
import NoteAddIcon from '@mui/icons-material/NoteAdd';
import { getStaticPath } from 'api/infernoApiService';

export interface HeaderProps {
  suiteTitle?: string;
}

const Header: FC<HeaderProps> = ({ suiteTitle }) => {
  const styles = useStyles();
  const history = useHistory();

  const returnHome = () => {
    history.push('/');
  };

  return !suiteTitle ? (
    <></>
  ) : (
    <AppBar position="sticky" color="default" className={styles.appbar}>
      <Container>
        <Box display="flex" justifyContent="center">
          <img
            src={getStaticPath(icon as string)}
            alt="inferno logo"
            className={styles.logo}
            onClick={returnHome}
          />
          <Typography variant="h6" component="div">
            {suiteTitle}
          </Typography>
        </Box>
        <Box>
          <Button
            color="secondary"
            onClick={returnHome}
            sx={{ marginTop: '10px' }}
            variant="outlined"
            disableElevation
            size="small"
            startIcon={<NoteAddIcon />}
          >
            New Session
          </Button>
        </Box>
      </Container>
    </AppBar>
  );
};

export default Header;
