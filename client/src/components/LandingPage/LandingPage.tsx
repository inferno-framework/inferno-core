import React, { FC, useEffect } from 'react';
import {
  Typography,
  Container,
  Button,
  Paper,
  List,
  ListItem,
  ListItemText,
} from '@material-ui/core';
import { TestSuite, TestSession } from 'models/testSuiteModels';
import useStyles from './styles';
import { useHistory } from 'react-router-dom';
import { getTestSuites } from 'api/TestSuitesApi';
import { postTestSessions } from 'api/TestSessionApi';

const LandingPage: FC<unknown> = () => {
  const [testSuites, setTestSuites] = React.useState<TestSuite[]>();
  const [testSuiteChosen, setTestSuiteChosen] = React.useState('');
  const styles = useStyles();
  const history = useHistory();

  useEffect(() => {
    if (!testSuites) {
      getTestSuites()
        .then((testSuites: TestSuite[]) => {
          setTestSuites(testSuites);
        })
        .catch((e) => {
          console.log(e);
        });
    } else if (testSuites.length === 1) {
      if (testSuiteChosen === '') {
        setTestSuiteChosen(testSuites[0].id);
      } else {
        createTestSession();
      }
    }
  });

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
      <div className={styles.leftSide}>
        <Typography variant="h2">FHIR Testing with Inferno</Typography>
        <Typography variant="h5">
          Test your server's conformance to authentication, authorization, and FHIR content
          standards.
        </Typography>
      </div>
      <Container maxWidth="md">
        <Paper elevation={4} className={styles.getStarted}>
          <Typography variant="h4" align="center">
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
            data-testid="go-button"
            className={styles.startTestingButton}
            onClick={() => createTestSession()}
          >
            Start Testing
          </Button>
        </Paper>
      </Container>
    </Container>
  );
};

export default LandingPage;
