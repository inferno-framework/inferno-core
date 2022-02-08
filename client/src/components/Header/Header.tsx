import React, { FC } from 'react';
import useStyles from './styles';
import icon from 'images/inferno_icon.png';
import { AppBar, Box, Container, Typography } from '@mui/material';
import { useHistory } from 'react-router-dom';

export interface HeaderProps {
  suiteTitle?: string;
}

const Header: FC<HeaderProps> = ({ suiteTitle }) => {
  const styles = useStyles();
  const history = useHistory();

  const returnHome = () => {
    history.push('/');
  };

  return (
    <AppBar position="sticky" color="default" className={styles.appbar}>
      <Container>
        <Box display="flex" justifyContent="center">
          <img
            src={icon as string}
            alt="inferno logo"
            className={styles.logo}
            onClick={returnHome}
          />
          <Typography variant="h6" component="div">
            {suiteTitle || 'Inferno'}
          </Typography>
        </Box>
      </Container>
    </AppBar>
  );
};

export default Header;
