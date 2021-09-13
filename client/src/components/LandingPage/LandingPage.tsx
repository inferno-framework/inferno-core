import React, { FC } from 'react';
import {
  Typography,
  Container,
  Button,
  Paper,
  List,
  ListItem,
  ListItemText,
} from '@material-ui/core';
import { TestSuite } from 'models/testSuiteModels';
import useStyles from './styles';

export interface LandingPageProps {
  testSuites: TestSuite[] | undefined;
  createTestSession: () => void;
  testSuiteChosen: string;
  setTestSuiteChosen: (id: string) => void;
}

const LandingPage: FC<LandingPageProps> = ({
  testSuites,
  createTestSession,
  testSuiteChosen,
  setTestSuiteChosen,
}) => {
  const styles = useStyles();

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
