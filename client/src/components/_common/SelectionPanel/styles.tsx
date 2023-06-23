import { makeStyles } from 'tss-react/mui';

export default makeStyles()(() => ({
  optionsList: {
    display: 'flex',
    flexDirection: 'column',
    margin: '0 16px',
    padding: '16px 0',
    borderRadius: '16px',
    overflow: 'auto',
  },
  selectedItem: {
    backgroundColor: 'rgba(248, 139, 48, 0.2) !important',
  },
}));
