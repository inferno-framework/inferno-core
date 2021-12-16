import { Theme } from '@mui/material/styles';

import makeStyles from '@mui/styles/makeStyles';

export default makeStyles((_theme: Theme) => ({
  modalTitle: {
    fontWeight: 600,
    fontSize: '1.5rem',
    display: 'flex',
  },
  modalTitleURL: {
    overflow: 'hidden',
    maxHeight: '1.6em',
    wordBreak: 'break-all',
    display: '-webkit-box',
    WebkitBoxOrient: 'vertical',
    WebkitLineClamp: '1',
    paddingRight: '8px',
  },
  modalTitleContainerShrink: {
    display: 'flex',
    flex: '0 1 auto',
    paddingRight: '8px',
  },
  modalTitleContainerNoShrink: {
    display: 'flex',
    flex: '1 0 auto',
    paddingRight: '8px',
  },
  modalTitleIcon: {
    display: 'flex',
    flex: '0 1 auto',
    padding: '0 16px',
    flexDirection: 'row-reverse',
  },
  modalContent: {
    display: 'flex',
  },
  section: {
    paddingBottom: '25px',
  },
  sectionHeader: {
    paddingBottom: '15px',
  },
  headerName: {
    fontWeight: 600,
  },
  codeblock: {
    width: '100%',
    overflow: 'auto',
    fontSize: 'small',
    marginTop: '10px',
  },
  inputIcon: {
    float: 'right',
    verticalAlign: 'middle',
    marginTop: '4px',
  },
}));
