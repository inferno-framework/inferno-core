import React, { FC } from 'react';
import Header from 'components/Header';
import LandingPage from 'components/LandingPage';
import ThemeProvider from 'components/ThemeProvider';
import { Container } from '@material-ui/core';
import { BrowserRouter as Router, Switch, Route } from 'react-router-dom';
import TestSessionWrapper from 'components/TestSuite/TestSessionWrapper';

const App: FC = () => {
  return (
    <Router>
      <ThemeProvider>
        <Header />
        <Container maxWidth="lg">
          <Switch>
            <Route exact path="/">
              <LandingPage />
            </Route>
            <Route path="/test_sessions/:test_session_id">
              <TestSessionWrapper />
            </Route>
          </Switch>
        </Container>
      </ThemeProvider>
    </Router>
  );
};

export default App;
