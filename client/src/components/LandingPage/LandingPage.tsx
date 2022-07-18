import React, { FC } from 'react';
import {
  Typography,
  Container,
  Button,
  Paper,
  List,
  ListItemText,
  ListItemButton,
  Box,
} from '@mui/material';
import { TestSuite, TestSession } from 'models/testSuiteModels';
import useStyles from './styles';
import { useHistory } from 'react-router-dom';
import { postTestSessions } from 'api/TestSessionApi';
import { useAppStore } from '~/store/app';

export interface LandingPageProps {
  testSuites: TestSuite[] | undefined;
}

const LandingPage: FC<LandingPageProps> = ({ testSuites }) => {
  const [testSuiteChosen, setTestSuiteChosen] = React.useState('');
  const windowIsSmall = useAppStore((state) => state.windowIsSmall);
  const styles = useStyles();
  const history = useHistory();

  function startTestingClick(): void {
    const testSuite = testSuites?.find((suite: TestSuite) => suite.id == testSuiteChosen);
    if (testSuite && testSuite.suite_options && testSuite.suite_options.length > 0) {
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
    <Container maxWidth="lg" className={styles.main} role="main">
      <Box display="flex" flexDirection="column" m={2} maxWidth="440px">
        <Typography variant="h2" component="h1">
          FHIR Testing with Inferno
        </Typography>
        <Typography variant="h5" component="h2">
          Test your server's conformance to authentication, authorization, and FHIR content
          standards.
        </Typography>
      </Box>
      <Box display="flex" justifyContent="center" height="fit-content">
        <Paper
          elevation={4}
          className={styles.getStarted}
          sx={{ width: windowIsSmall ? 'auto' : '400px' }}
        >
          <Typography variant="h4" component="h2" align="center">
            Select a Test Suite
          </Typography>
          <List>
            {testSuites?.map((testSuite: TestSuite) => {
              return (
                // Use li to resolve a11y error
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
      </Box>
    </Container>
  );
};

export default LandingPage;
