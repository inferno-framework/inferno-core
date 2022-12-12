import React, { FC } from 'react';
import useStyles from './styles';
import { Box, Link, Typography, Divider, IconButton, MenuItem, Menu } from '@mui/material';
import logo from '~/images/inferno_logo.png';
import { getStaticPath } from '~/api/infernoApiService';
import { FooterLink } from '~/models/testSuiteModels';
import { useAppStore } from '~/store/app';
import { Help } from '@mui/icons-material';

interface FooterProps {
  version: string;
  linkList?: FooterLink[];
}

const Footer: FC<FooterProps> = ({ version, linkList }) => {
  const footerHeight = useAppStore((state) => state.footerHeight);
  const windowIsSmall = useAppStore((state) => state.windowIsSmall);
  const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);
  const [showMenu, setShowMenu] = React.useState<boolean>(false);
  const styles = useStyles();

  const renderLogoText = () => {
    if (!version) return <></>;
    return (
      <Box display="flex" flexDirection="column">
        {!windowIsSmall && (
          <Typography className={styles.logoText} style={{ fontSize: '0.7rem' }}>
            Built with
          </Typography>
        )}
        <Typography
          className={styles.logoText}
          style={{ fontSize: windowIsSmall ? '0.7rem' : '0.9rem' }}
        >
          {`v.${version}`}
        </Typography>
      </Box>
    );
  };

  const renderLinksMenu = () => {
    return (
      <Box display="flex" alignItems="center" data-testid="footer-links">
        <IconButton
          aria-label="links"
          size="small"
          color="secondary"
          onClick={(e) => {
            setAnchorEl(!anchorEl ? e.currentTarget : null);
            setShowMenu(!showMenu);
          }}
        >
          <Help fontSize="inherit" />
        </IconButton>

        {linkList && showMenu && (
          <Menu
            anchorEl={anchorEl}
            open={showMenu}
            MenuListProps={{ dense: true }}
            onClose={() => {
              setShowMenu(false);
              setAnchorEl(null);
            }}
          >
            {linkList.map((link) => {
              return (
                <MenuItem key={link.url}>
                  <Link
                    href={link.url}
                    target="_blank"
                    rel="noreferrer"
                    underline="hover"
                    className={styles.linkText}
                    style={{
                      fontSize: '0.8rem',
                    }}
                  >
                    {link.label}
                  </Link>
                </MenuItem>
              );
            })}
          </Menu>
        )}
      </Box>
    );
  };

  const renderLinks = () => {
    return (
      <Box display="flex" alignItems="center" p={2} data-testid="footer-links">
        {linkList &&
          linkList.map((link, i) => {
            return (
              <React.Fragment key={link.url}>
                <Link
                  href={link.url}
                  target="_blank"
                  rel="noreferrer"
                  underline="hover"
                  className={styles.linkText}
                  style={{
                    fontSize: '1.1rem',
                    margin: '0 16px',
                  }}
                >
                  {link.label}
                </Link>
                {i !== linkList.length - 1 && <Divider orientation="vertical" flexItem />}
              </React.Fragment>
            );
          })}
      </Box>
    );
  };

  return (
    <footer
      className={styles.footer}
      style={{ minHeight: `${footerHeight}px`, maxHeight: `${footerHeight}px` }}
    >
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
              className={windowIsSmall ? styles.mobileLogo : styles.logo}
            />
          </Link>
          {renderLogoText()}
        </Box>
        {windowIsSmall ? renderLinksMenu() : renderLinks()}
      </Box>
    </footer>
  );
};

export default Footer;
