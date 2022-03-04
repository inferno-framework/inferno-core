import React, { FC } from 'react';
import useStyles from './styles';
import { Container, Box, Link, Typography } from '@mui/material';
import logo from 'images/inferno_logo.png';
import { getStaticPath } from 'api/infernoApiService';

interface FooterProps {
  version: string;
}

const Footer: FC<FooterProps> = ({ version }) => {
  const styles = useStyles();
  return (
    <Box className={styles.footer}>
      <Container>
        <Box className={styles.builtUsingContainer}>
          <Typography className={styles.builtUsing}>built using</Typography>
          <Link
            href="https://inferno-framework.github.io/inferno-core"
            target="_blank"
            rel="noreferrer"
          >
            <img
              src={getStaticPath(logo as string)}
              alt="Inferno logo - documentation"
              className={styles.logo}
            />
          </Link>
          {version && (
            <Typography variant="overline" className={styles.version}>
              {`version ${version}`}
            </Typography>
          )}
        </Box>
      </Container>
    </Box>
  );
};

export default Footer;
