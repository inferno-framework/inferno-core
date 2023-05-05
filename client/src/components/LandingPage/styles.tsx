import { Theme } from '@mui/material/styles';
import { makeStyles } from 'tss-react/mui';

export default makeStyles()((theme: Theme) => ({
  main: {
    display: 'flex',
    flexWrap: 'wrap',
    alignItems: 'center',
    justifyContent: 'space-evenly',
    backgroundColor: theme.palette.common.white,
  },
  selectedItem: {
    backgroundColor: 'rgba(248, 139, 48, 0.2) !important',
  },
  optionsList: {
    display: 'flex',
    flexDirection: 'column',
    margin: '20px',
    padding: '16px',
    borderRadius: '16px',
    overflow: 'auto',
  },
}));
