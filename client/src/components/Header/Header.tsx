import React, { FC } from 'react';
import useStyles from './styles';
import logo from 'images/inferno_logo.png';
import { Button, Container } from '@material-ui/core';
import { useHistory } from 'react-router-dom';

const Header: FC<unknown> = () => {
  const styles = useStyles();
  const history = useHistory();
  function returnHome() {
    history.push('/');
  }
  return (
    <header className={styles.header}>
      <Container maxWidth="lg">
        <Button onClick={() => returnHome()}>
          <img src={logo as string} alt="inferno logo" className={styles.logo} />
        </Button>
      </Container>
    </header>
  );
};

export default Header;
