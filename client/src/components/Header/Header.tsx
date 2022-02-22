import React, { FC } from 'react';
import useStyles from './styles';
import icon from 'images/inferno_icon.png';
import { AppBar, Box, Button, Link, Toolbar, Typography } from '@mui/material';
import { useHistory } from 'react-router-dom';
import NoteAddIcon from '@mui/icons-material/NoteAdd';
import { getStaticPath } from 'api/infernoApiService';

export interface HeaderProps {
  suiteTitle?: string;
  suiteVersion?: string;
}

const Header: FC<HeaderProps> = ({ suiteTitle, suiteVersion }) => {
  const styles = useStyles();
  const history = useHistory();

  const returnHome = () => {
    history.push('/');
  };

  return suiteTitle ? (
    <AppBar color="default" className={styles.appbar}>
      <Toolbar className={styles.toolbar}>
        <Box display="flex" justifyContent="center">
          <Link href="/">
            <img src={getStaticPath(icon as string)} alt="inferno logo" className={styles.logo} />
          </Link>
          <Typography variant="h5" component="h1" className={styles.title}>
            {suiteTitle}
          </Typography>
          <Typography variant="subtitle1" className={styles.version}>
            {suiteVersion ? 'v ' + suiteVersion : ''}
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
