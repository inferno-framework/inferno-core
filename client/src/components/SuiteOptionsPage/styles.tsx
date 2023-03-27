import { Theme } from '@mui/material/styles';
import { makeStyles } from 'tss-react/mui';

export default makeStyles()((theme: Theme) => ({
  container: {
    backgroundColor: theme.palette.common.white,
  },
  main: {
    display: 'flex',
    flexWrap: 'wrap',
    alignItems: 'center',
    justifyContent: 'space-evenly',
  },
  optionsList: {
    display: 'flex',
    flexDirection: 'column',
    padding: '16px 0',
    borderRadius: '16px',
    overflow: 'auto',
  },
}));
