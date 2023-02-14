import React from 'react';
import ReactDOM from 'react-dom';
import './index.css';
import App from 'components/App';
import reportWebVitals from './reportWebVitals';
import { SnackbarProvider } from 'notistack';
import SnackbarCloseButton from 'components/_common/SnackbarCloseButton';

ReactDOM.render(
  <React.StrictMode>
    <SnackbarProvider
      dense
      maxSnack={3}
      anchorOrigin={{
        vertical: 'bottom',
        horizontal: 'right',
      }}
      action={(id) => <SnackbarCloseButton id={id} />}
      style={{ marginBottom: '52px' }}
    >
      <App />
    </SnackbarProvider>
  </React.StrictMode>,
  document.getElementById('root')
);

// If you want to start measuring performance in your app, pass a function
// to log results (for example: reportWebVitals(console.log))
// or send to an analytics endpoint. Learn more: https://bit.ly/CRA-vitals
reportWebVitals();
