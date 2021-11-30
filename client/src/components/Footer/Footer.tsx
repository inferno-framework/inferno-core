import React, { FC } from 'react';
import useStyles from './styles';
import { Link } from '@mui/material';

interface FooterProps {
  githubLink?: string;
  versionNumber?: string;
}

const Footer: FC<FooterProps> = ({ githubLink, versionNumber }) => {
  const styles = useStyles();
  return (
    <nav className={styles.footer}>
      <div className={styles.footerElement}>
        <Link href={githubLink} target="_blank" rel="noreferrer" underline="hover">
          Open Source
        </Link>
      </div>
      <div className={styles.footerElement}>Version {versionNumber}</div>
    </nav>
  );
};

export default Footer;
