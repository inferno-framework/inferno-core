import { makeStyles } from 'tss-react/mui';

export default makeStyles()(() => ({
  main: {
    display: 'flex',
    flexWrap: 'wrap',
    alignItems: 'initial',
    justifyContent: 'space-evenly',
    height: '100%',
    padding: '0 !important',
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
  },
}));
