import { makeStyles, Theme } from '@material-ui/core/styles';

export default makeStyles((_theme: Theme) => ({
  textarea: {
    resize: 'vertical',
    maxHeight: '400px',
    overflow: 'auto !important',
  },
}));
