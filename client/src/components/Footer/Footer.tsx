import React, { FC } from 'react';
import useStyles from './styles';
import { Box, Link, Typography, Divider } from '@mui/material';
import logo from 'images/inferno_logo.png';
import { getStaticPath } from 'api/infernoApiService';

interface FooterProps {
  version: string;
}

const Footer: FC<FooterProps> = ({ version }) => {
  const styles = useStyles();
  return (
    <footer className={styles.footer}>
      <Box display="flex" flexDirection="row" justifyContent="space-between">
        <Box display="flex" alignItems="center" px={2}>
          <Link
            href="https://inferno-framework.github.io/inferno-core"
            target="_blank"
            rel="noreferrer"
            aria-label="Inferno"
          >
            <img
              src={getStaticPath(logo as string)}
              alt="Inferno logo - documentation"
              className={styles.logo}
            />
          </Link>
          {version && (
            <Box display="flex" flexDirection="column">
              <Typography className={styles.logoText} style={{ fontSize: '0.7rem' }}>
                Built with
              </Typography>
              <Typography className={styles.logoText} style={{ fontSize: '0.9rem' }}>
                {`v.${version}`}
              </Typography>
            </Box>
          )}
        </Box>
        <Box display="flex" alignItems="center" p={2}>
          <Link
            href="https://inferno-framework.github.io/inferno-core"
            target="_blank"
            rel="noreferrer"
            color="secondary"
            className={styles.linkText}
          >
            Open Source
          </Link>
          <Divider orientation="vertical" flexItem />
          <Link
            href="https://inferno-framework.github.io/inferno-core"
            target="_blank"
            rel="noreferrer"
            color="secondary"
            className={styles.linkText}
          >
            Issues
          </Link>
        </Box>
      </Box>
    </footer>
  );
};

export default Footer;
