import React, { FC } from 'react';
import useStyles from './styles';
import logo from 'images/inferno_logo.png';
import { Button, Chip, Container } from '@material-ui/core';
import { useHistory } from 'react-router-dom';

interface HeaderProps {
  chipLabel?: string;
}

const Header: FC<HeaderProps> = ({ chipLabel }) => {
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
        {chipLabel && <Chip label={chipLabel} size="small" />}
      </Container>
    </header>
  );
};

export default Header;
