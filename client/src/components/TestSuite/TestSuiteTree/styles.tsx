import { Theme } from '@mui/material/styles';
import { makeStyles } from 'tss-react/mui';

export default makeStyles()((theme: Theme) => ({
  labelRoot: {
    display: 'flex',
    flex: '1 1 auto',
    alignItems: 'center',
    padding: theme.spacing(0.5, 0),
  },
  labelText: {
    display: 'inline',
  },
  optionalLabel: {
    display: 'inline',
    fontStyle: 'italic',
    alignSelf: 'center',
    color: theme.palette.common.gray,
    paddingLeft: '8px',
  },
  shortId: {
    display: 'inline',
    fontWeight: 'bold',
    alignSelf: 'center',
    color: theme.palette.common.grayDark,
  },
  testSuiteTreePanel: {
    display: 'flex',
    flexDirection: 'column',
    width: '300px',
    flexGrow: 1,
    overflow: 'hidden',
  },
  testSuiteTree: {
    height: '100%',
    display: 'flex',
    flexDirection: 'column',
    overflowY: 'auto',
  },
  treeRoot: {
    '& $labelText': {
      textTransform: 'uppercase',
      fontWeight: 'bold',
    },
    padding: '8px 20px !important',
  },
  treeItemTopBorder: {
    borderTop: `1px solid ${theme.palette.divider}`,
  },
  treeItemBottomBorder: {
    borderBottom: `1px solid ${theme.palette.divider}`,
  },
}));
