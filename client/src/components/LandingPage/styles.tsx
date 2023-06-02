import { Theme } from '@mui/material/styles';
import { makeStyles } from 'tss-react/mui';

export default makeStyles()((theme: Theme) => ({
  main: {
    display: 'flex',
    flexWrap: 'wrap',
    alignItems: 'initial',
    justifyContent: 'space-evenly',
    height: '100%',
    padding: '0 !important',
  },
  title: {
    color: theme.palette.common.grayDark,
    fontWeight: 'bolder',
  },
  flexContainer: {
    display: 'flex',
    flexDirection: 'column',
    justifyContent: 'center',
    alignItems: 'center',
  },
  leftBorder: {
    borderLeft: '4px solid',
    borderColor: theme.palette.common.grayLighter,
  },
}));
