import { Theme } from '@mui/material/styles';
import { makeStyles } from 'tss-react/mui';

export default makeStyles()((theme: Theme) => ({
  root: {
    backgroundColor: theme.palette.background.paper,
  },
  currentItem: {
    fontWeight: 600,
  },
  shortId: {
    display: 'inline',
    fontWeight: 'bold',
    alignSelf: 'center',
    color: theme.palette.common.grayDark,
  },
  testGroupCardHeader: {
    display: 'flex',
    overflow: 'auto',
    alignItems: 'center',
    minHeight: '36.5px',
    padding: '8px 16px',
    backgroundColor: theme.palette.common.blueLightest,
    '@media print': {
      padding: '0 8px',
    },
  },
  testGroupCardHeaderText: {
    flexGrow: 1,
    padding: '0 8px',
  },
  testGroupCardHeaderButton: {
    minWidth: 'fit-content',
    '@media print': {
      display: 'none',
    },
  },
  reportSummaryItems: {
    padding: '16px;',
    display: 'flex',
    justifyContent: 'space-around',
    textAlign: 'center',
  },
  reportSummaryURL: {
    textAlign: 'right',
    padding: '0 8px;',
    fontSize: '12px',
    wordBreak: 'break-word',
  },
  alert: {
    marginBottom: '8px',
    alignItems: 'center',
    printColorAdjust: 'exact',
    WebkitPrintColorAdjust: 'exact',
    '& .MuiAlert-message': { width: '100%' },
  },
  alertMessage: {
    display: '-webkit-box',
    WebkitBoxOrient: 'vertical',
    WebkitLineClamp: '1',
    overflow: 'hidden',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  alertCursor: {
    '& :hover': {
      cursor: 'pointer',
    },
  },
}));
