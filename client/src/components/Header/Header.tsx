import React, { FC } from 'react';
import useStyles from './styles';
import logo from 'images/inferno_logo.png';
import { AppBar, Toolbar, Link } from '@mui/material';
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
        <Link onClick={returnHome} component="button">
          <img src={logo as string} alt="inferno logo" className={styles.logo} />
        </Link>
      </Toolbar>
    </AppBar>
  );
};

export default Header;
