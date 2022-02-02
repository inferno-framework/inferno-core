import React, { FC } from 'react';
import useStyles from './styles';
import { Container, Box, Link, Typography } from '@mui/material';
import logo from 'images/inferno_logo.png';

interface FooterProps {
  githubLink?: string;
  versionNumber?: string;
}

const Footer: FC<FooterProps> = ({ githubLink, versionNumber }) => {
  const styles = useStyles();
  const version = versionNumber || 'v ?.?.?';
  return (
    <Box sx={{ width: '100%', zIndex: '5000', backgroundColor: '#f0ece7' }}>
      <Container sx={{ display: 'flex', justifyContent: 'center' }}>
        <Box display="flex" paddingRight="10px">
          <Typography
            sx={{
              display: 'flex',
              flexDirection: 'column',
              justifyContent: 'center',
              paddingRight: '5px',
              fontStyle: 'italic',
            }}
          >
            built using
          </Typography>
          <img src={logo as string} alt="inferno logo" className={styles.logo} />
        </Box>
        <Typography
          sx={{
            display: 'flex',
            flexDirection: 'column',
            justifyContent: 'center',
            paddingRight: '5px',
          }}
        >
          |
        </Typography>
        <Typography
          sx={{
            display: 'flex',
            flexDirection: 'column',
            justifyContent: 'center',
            paddingRight: '5px',
          }}
        >
          {version}{' '}
        </Typography>
        <Typography
          sx={{
            display: 'flex',
            flexDirection: 'column',
            justifyContent: 'center',
            paddingRight: '5px',
          }}
        >
          |
        </Typography>
        <Link
          sx={{ display: 'flex', flexDirection: 'column', justifyContent: 'center' }}
          href={githubLink}
          target="_blank"
          rel="noreferrer"
          underline="hover"
        >
          API
        </Link>
      </Container>
    </Box>
  );
};

export default Footer;
