import { Theme } from '@mui/material/styles';
import { makeStyles } from 'tss-react/mui';

export default makeStyles()((theme: Theme) => ({
  label: {
    '& label.Mui-focused': {
      color: theme.palette.primary.dark,
    },
  },
  optionsList: {
    display: 'flex',
    flexDirection: 'column',
    margin: '0 16px',
    padding: '16px 0',
    borderRadius: '16px',
    overflow: 'auto',
    maxHeight: '600px', // TODO: Change to dynamic value based on screen height
  },
  selectedItem: {
    backgroundColor: `${theme.palette.common.orangeLight} !important`,
  },
}));
