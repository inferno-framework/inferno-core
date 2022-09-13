import { Theme } from '@mui/material/styles';
import makeStyles from '@mui/styles/makeStyles';

export default makeStyles((theme: Theme) => ({
  root: {
    backgroundColor: theme.palette.background.paper,
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
  labelText: {
    display: 'inline',
  },
  testGroupCardHeader: {
    display: 'flex',
    overflow: 'auto',
    alignItems: 'center',
    minHeight: '36.5px',
    padding: '8px 16px',
    backgroundColor: theme.palette.common.blueGrayLightest,
    '@media print': {
      padding: '0 8px',
    },
  },
  testGroupCardList: {
    padding: 0,
  },
  testGroupCardHeaderText: {
    flexGrow: 1,
    padding: '0 8px',
  },
  shortId: {
    display: 'inline',
    fontWeight: 'bold',
    alignSelf: 'center',
    color: theme.palette.common.grayDarkest,
  },
  testGroupCardHeaderButton: {
    minWidth: 'fit-content',
    '@media print': {
      display: 'none',
    },
  },
  descriptionPanel: {
    padding: '16px',
    overflow: 'auto',
  },
  currentItem: {
    fontWeight: 600,
  },
  accordion: {
    '&:before': {
      display: 'none',
    },
    '&:not(last-child)': {
      borderBottom: `1px solid ${theme.palette.divider}`,
    },
    '@media print': {
      borderBottom: 'none !important',
    },
  },
  accordionSummary: {
    userSelect: 'auto',
    '@media print': {
      minHeight: 'unset',
    },
    '& .MuiAccordionSummary-content': {
      margin: 0,
    },
  },
  accordionDetailContainer: {
    backgroundColor: theme.palette.common.grayLighter,
    '@media print': {
      padding: '0 0 0 16px',
    },
  },
  accordionDetail: {
    backgroundColor: theme.palette.common.white,
    padding: 0,
    margin: '8px 0 0 0',
    borderRadius: '4px',
    '@media print': {
      margin: 0,
    },
  },
  nestedDescription: {
    padding: '8px 16px 24px 16px',
  },
  nestedDescriptionHeader: {
    fontWeight: 'bolder !important',
    color: theme.palette.common.orangeDarker,
  },
  nestedDescriptionContainer: {
    backgroundColor: theme.palette.common.grayLighter,
    padding: '8px 0',
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
