import { Theme } from '@mui/material/styles';

import makeStyles from '@mui/styles/makeStyles';

export default makeStyles((_theme: Theme) => ({
  modalTitle: {
    fontWeight: 600,
    fontSize: '1.5rem',
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
