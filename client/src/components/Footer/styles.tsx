import makeStyles from '@mui/styles/makeStyles';

export default makeStyles(() => ({
  footer: {
    width: '100%',
    zIndex: '5000',
    backgroundColor: '#f0ece7',
    '& .MuiContainer-root': {
      display: 'flex',
      justifyContent: 'center',
    },
  },
  builtUsing: {
    display: 'flex',
    paddingRight: '10px',
    '& p': {
      display: 'flex',
      flexDirection: 'column',
      justifyContent: 'center',
      padding: '10px',
      fontStyle: 'italic',
    },
  },
  logo: {
    objectFit: 'contain',
    height: '2.5em',
    marginTop: '-2px',
  },
}));
