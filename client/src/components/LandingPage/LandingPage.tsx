import React, { FC } from 'react';
import {
  Typography,
  Container,
  Button,
  Paper,
  List,
  ListItemText,
  Grid,
  ListItemButton,
} from '@mui/material';
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

  function startTestingClick(): void {
    const testSuite = testSuites?.find((suite: TestSuite) => suite.id == testSuiteChosen);
    if(testSuite && testSuite.suite_options && testSuite.suite_options.length > 0){
        history.push(`${testSuiteChosen}`);
    } else {
      postTestSessions(testSuiteChosen, null, null)
        .then((testSession: TestSession | null) => {
          if (testSession && testSession.test_suite) {
            history.push('test_sessions/' + testSession.id);
          }
        })
        .catch((e) => {
          console.log(e);
        });
    }
  }

  return (
    <>
      <Container maxWidth="lg" className={styles.main} role="main">
        <Grid container spacing={10} justifyContent="center">
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
          <Grid container item xs={6} alignItems="center" justifyContent="center">
            <Grid item>
              <Paper elevation={4} className={styles.getStarted}>
                <Typography variant="h4" component="h2" align="center">
                  Select a Test Suite
                </Typography>
                <List>
                  {testSuites?.map((testSuite: TestSuite) => {
                    return (
                      /* Use li to resolve a11y error */
                      <li key={testSuite.id}>
                        <ListItemButton
                          data-testid="testing-suite-option"
                          selected={testSuiteChosen === testSuite.id}
                          onClick={() => setTestSuiteChosen(testSuite.id)}
                          classes={{ selected: styles.selectedItem }}
                        >
                          <ListItemText primary={testSuite.title} />
                        </ListItemButton>
                      </li>
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
                  onClick={() => startTestingClick()}
                >
                  Start Testing
                </Button>
              </Paper>
            </Grid>
          </Grid>
        </Grid>
      </Container>
    </>
  );
};

export default LandingPage;
