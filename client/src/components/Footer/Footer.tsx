import React, { FC } from 'react';
import { Box, Link, Typography, Divider, IconButton, MenuItem, Menu } from '@mui/material';
import { Help } from '@mui/icons-material';
import logo from '~/images/inferno_logo.png';
import { basePath, getStaticPath } from '~/api/infernoApiService';
import { FooterLink } from '~/models/testSuiteModels';
import { useAppStore } from '~/store/app';
import useStyles from './styles';

interface FooterProps {
  version: string;
  linkList?: FooterLink[];
}

const Footer: FC<FooterProps> = ({ version, linkList }) => {
  const { classes } = useStyles();
  const footerHeight = useAppStore((state) => state.footerHeight);
  const windowIsSmall = useAppStore((state) => state.windowIsSmall);
  const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);
  const [showMenu, setShowMenu] = React.useState<boolean>(false);

  const apiLink = () => {
    // To test locally, set apiBase to 'http://127.0.0.1:4000/inferno-core/api-docs/'
    const apiBase = 'https://inferno-framework.github.io/inferno-core/api-docs/';
    const hostname = window.location.host;
    const fullHost = `${hostname}/${basePath}`;
    const scheme = window.location.protocol;

    return (
      <Box display="flex">
        <Link
          href={`${apiBase}?scheme=${scheme}&host=${fullHost}`}
          target="_blank"
          rel="noreferrer"
          color="secondary"
          className={classes.link}
          sx={{ fontSize: windowIsSmall ? '0.7rem' : '0.9rem' }}
        >
          API
        </Link>
      </Box>
    );
  };

  const renderLogoText = () => {
    if (!version) return apiLink();
    return (
      <Box display="flex" flexDirection="column">
        {!windowIsSmall && (
          <Typography className={classes.logoText} sx={{ fontSize: '0.7rem' }}>
            Built with
          </Typography>
        )}
        <Box display="flex" flexDirection="row" alignItems="center">
          <Box>
            <Typography
              className={classes.logoText}
              sx={{ fontSize: windowIsSmall ? '0.7rem' : '0.9rem' }}
            >
              {`v.${version}`}
            </Typography>
          </Box>
          <Divider flexItem orientation="vertical" sx={{ margin: '4px 8px' }} />
          {apiLink()}
        </Box>
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
                    color="secondary"
                    className={classes.link}
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
                  color="secondary"
                  className={classes.link}
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
      className={classes.footer}
      style={{
        minHeight: `${footerHeight}px`,
        maxHeight: `${footerHeight}px`,
      }}
    >
      <Box
        display="flex"
        flexDirection="row"
        justifyContent="space-between"
        overflow="auto"
        width="100%"
      >
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
              className={windowIsSmall ? classes.mobileLogo : classes.logo}
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
