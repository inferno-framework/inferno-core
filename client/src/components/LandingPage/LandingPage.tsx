import React, { FC } from 'react';
import {
  Typography,
  Container,
  Button,
  Paper,
  List,
  ListItem,
  ListItemText,
  Grid,
} from '@material-ui/core';
import { TestSuite, TestSession } from 'models/testSuiteModels';
import useStyles from './styles';
import { useHistory } from 'react-router-dom';
import { postTestSessions } from 'api/TestSessionApi';

export interface LandingPageProps {
  testSuites: TestSuite[] | undefined;
}

const LandingPage: FC<LandingPageProps> = ({ testSuites }) => {
  const [testSuiteChosen, setTestSuiteChosen] = React.useState('');
  const styles = useStyles();
  const history = useHistory();

  function createTestSession(): void {
    postTestSessions(testSuiteChosen)
      .then((testSession: TestSession | null) => {
        if (testSession && testSession.test_suite) {
          history.push('test_sessions/' + testSession.id);
        }
      })
      .catch((e) => {
        console.log(e);
      });
  }

  return (
    <Container maxWidth="lg" className={styles.main}>
      <Grid container spacing={10} justify="center">
        <Grid container item xs={6} alignItems="center">
          <Grid item>
            <Typography variant="h2" component="h1">
              FHIR Testing with Inferno
            </Typography>
            <Typography variant="h5" component="h2">
              Test your server's conformance to authentication, authorization, and FHIR content
              standards.
            </Typography>
          </Grid>
        </Grid>
        <Grid container item xs={6} alignItems="center" justify="center">
          <Grid item>
            <Paper elevation={4} className={styles.getStarted}>
              <Typography variant="h4" component="h2" align="center">
                Select a Test Suite
              </Typography>
              <List>
                {testSuites?.map((testSuite: TestSuite) => {
                  return (
                    <ListItem
                      key={testSuite.id}
                      button
                      selected={testSuiteChosen == testSuite.id}
                      onClick={() => setTestSuiteChosen(testSuite.id)}
                      classes={{ selected: styles.selectedItem }}
                    >
                      <ListItemText primary={testSuite.title} />
                    </ListItem>
                  );
                })}
              </List>
              <Button
                variant="contained"
                size="large"
                color="primary"
                fullWidth
                disabled={!testSuiteChosen}
                data-testid="go-button"
                className={styles.startTestingButton}
                onClick={() => createTestSession()}
              >
                Start Testing
              </Button>
            </Paper>
          </Grid>
        </Grid>
      </Grid>
    </Container>
  );
};

export default LandingPage;
