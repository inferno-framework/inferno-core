import { Theme } from '@mui/material/styles';
import makeStyles from '@mui/styles/makeStyles';

export default makeStyles((theme: Theme) => ({
  root: {
    backgroundColor: theme.palette.background.paper,
  },
  reportSummaryBox: {
    padding: '5px',
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
  },
  testIcon: {
    padding: '0 8px 0 0',
    display: 'inline-flex',
  },
  labelText: {
    display: 'inline',
  },
  testGroupCardHeader: {
    padding: '8px 16px',
    fontWeight: 600,
    fontSize: '16px',
    borderBottom: '1px solid rgba(0,0,0,.12)',
    backgroundColor: theme.palette.common.blueGrayLightest,
    borderTopLeftRadius: '4px',
    borderTopRightRadius: '4px',
    display: 'flex',
    minHeight: '36.5px',
    alignItems: 'center',
    '@media print': {
      padding: '0 8px',
    },
  },
  testGroupCard: {
    marginBottom: '24px',
  },
  testGroupCardList: {
    padding: 0,
  },
  testGroupCardHeaderText: {
    flexGrow: 1,
  },
  shortId: {
    display: 'inline',
    fontWeight: 'bold',
    alignSelf: 'center',
    color: theme.palette.common.grayVeryDark,
  },
  testGroupCardHeaderButton: {
    minWidth: 'fit-content',
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
    '@media print': {
      minHeight: 'unset',
      '& .MuiAccordionSummary-content': {
        margin: 0,
      },
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
  printButton: {
    '@media print': {
      display: 'none',
    },
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
