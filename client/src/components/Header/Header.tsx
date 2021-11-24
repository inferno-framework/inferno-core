import React, { FC } from 'react';
import useStyles from './styles';
import logo from 'dne.png';
// import logo from 'images/inferno_logo.png';
import { Button, AppBar, Toolbar } from '@mui/material';
import { useHistory } from 'react-router-dom';

const Header: FC<unknown> = () => {
  const styles = useStyles();
  const history = useHistory();

  const returnHome = () => {
    history.push('/');
  };

  return (
    <AppBar position="sticky" color="default" className={styles.appbar}>
      <Toolbar>
        <Button onClick={returnHome}>
          <img src={logo as string} alt="inferno logo" className={styles.logo} />
        </Button>
      </Toolbar>
    </AppBar>
  );
};

export default Header;
