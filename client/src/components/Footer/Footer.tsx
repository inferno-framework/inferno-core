import React, { FC } from 'react';
import useStyles from './styles';
import { Box, Link, Typography, Divider } from '@mui/material';
import logo from '~/images/inferno_logo.png';
import { getStaticPath } from '~/api/infernoApiService';

interface FooterProps {
  version: string;
}

const Footer: FC<FooterProps> = ({ version }) => {
  const styles = useStyles();
  const linkList = [
    { label: 'Open Source', url: 'https://github.com/inferno-framework/inferno-core' },
    { label: 'Issues', url: 'https://github.com/inferno-framework/inferno-core/issues' },
  ];

  return (
    <footer className={styles.footer}>
      <Box display="flex" flexDirection="row" justifyContent="space-between" overflow="auto">
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
          {linkList.map((link, i) => {
            return (
              <React.Fragment key={link.url}>
                <Link
                  href={link.url}
                  target="_blank"
                  rel="noreferrer"
                  underline="hover"
                  className={styles.linkText}
                >
                  {link.label}
                </Link>
                {i !== linkList.length - 1 && <Divider orientation="vertical" flexItem />}
              </React.Fragment>
            );
          })}
        </Box>
      </Box>
    </footer>
  );
};

export default Footer;
