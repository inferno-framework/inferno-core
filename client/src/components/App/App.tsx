import React, { FC } from 'react';
import ThemeProvider from 'components/ThemeProvider';
import { BrowserRouter as Router } from 'react-router-dom';
import Inferno from 'components/App/Inferno';

const App: FC<unknown> = () => {
  return (
    <Router>
      <ThemeProvider>
        <Inferno />
      </ThemeProvider>
    </Router>
  );
};

export default App;
