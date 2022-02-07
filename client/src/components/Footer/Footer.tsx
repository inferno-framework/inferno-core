import React, { FC } from 'react';
import useStyles from './styles';
import { Container, Box, Link, Typography } from '@mui/material';
import logo from 'images/inferno_logo.png';

interface FooterProps {
  versionNumber?: string;
}

const Footer: FC<FooterProps> = ({ versionNumber }) => {
  const styles = useStyles();
  const version = versionNumber || '';
  return (
    <Box className={styles.footer}>
      <Container>
        <Box className={styles.builtUsing}>
          <Typography>
            built using
          </Typography>
          <Link
            sx={{ display: 'flex', flexDirection: 'column', justifyContent: 'center' }}
            href={'https://inferno-framework.github.io/inferno-core'}
            target="_blank"
            rel="noreferrer"
            underline="hover"
          >
            <img src={logo as string} alt="inferno logo" className={styles.logo} />
          </Link>
          <Typography>{version}</Typography>
        </Box>
      </Container>
    </Box>
  );
};

export default Footer;
