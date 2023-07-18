import { Theme } from '@mui/material/styles';
import { makeStyles } from 'tss-react/mui';

export default makeStyles()((theme: Theme) => ({
  root: {
    backgroundColor: theme.palette.background.paper,
  },
  configCardHeader: {
    padding: '8px 16px',
    fontWeight: 600,
    fontSize: '16px',
    borderBottom: `1px solid ${theme.palette.common.grayLighter}`,
    backgroundColor: theme.palette.common.blueGrayLightest,
    borderTopLeftRadius: '4px',
    borderTopRightRadius: '4px',
    display: 'flex',
    minHeight: '36.5px',
    alignItems: 'center',
  },
  configCardHeaderText: {
    flexGrow: 1,
  },
  currentItem: {
    fontWeight: 600,
  },
  tab: {
    pointerEvents: 'auto',
    '&:hover, :focus-within': {
      color: theme.palette.common.grayDarker,
      fontWeight: 'bolder',
    },
    '&.Mui-selected': {
      color: theme.palette.common.orangeDarker,
      fontWeight: 'bolder',
    },
  },
}));
