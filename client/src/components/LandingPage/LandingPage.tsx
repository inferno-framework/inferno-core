import React, { FC, useEffect } from 'react';
import {
  Typography,
  Container,
  Button,
  Paper,
  Select,
  MenuItem,
  InputLabel,
  FormControl,
  Grid,
  Divider,
} from '@material-ui/core';
import { TestSuite, TestSession } from 'models/testSuiteModels';
import { getTestSuites, postTestSessions } from 'api/infernoApiService';
import useStyles from './styles';
import { useHistory } from 'react-router-dom';

interface preset {
  name: string;
  fhirServer: string;
  testSet: string;
}

interface LandingPageProps {
  presets: preset[];
}

const LandingPage: FC<LandingPageProps> = ({ presets }) => {
  const [testSuites, setTestSuites] = React.useState<TestSuite[]>([]);
  const [testSuiteChosen, setTestSuiteChosen] = React.useState('');
  const [presetChosen, setPresetChosen] = React.useState(0);
  const styles = useStyles();
  const history = useHistory();

  useEffect(() => {
    if (testSuites.length == 0) {
      getTestSuites()
        .then((testSuites: TestSuite[]) => {
          setTestSuites(testSuites);
        })
        .catch((e) => {
          console.log(e);
        });
    }
  });

  function createTestSession(): void {
    postTestSessions(testSuiteChosen)
      .then((testSession: TestSession) => {
        if (testSession.test_suite) {
          history.push('test_sessions/' + testSession.id);
        }
      })
      .catch((e) => {
        console.log(e);
      });
  }

  return (
    <div className={styles.main}>
      <Container maxWidth="md">
        <Typography variant="h2">FHIR Testing with Inferno</Typography>
        <Typography variant="h5" className={styles.descriptionText}>
          Inferno is an open source tool that tests whether patients can access their health data.
          Test your server's conformance to authentication, authorization, and FHIR content
          standards :)
        </Typography>
        <Container maxWidth="md">
          <Paper elevation={4} className={styles.getStarted}>
            <Container maxWidth="md">
              <Typography variant="h4" align="center">
                Start Testing
              </Typography>
              <Grid container className={styles.inputGrid}>
                <Grid item xs={7}>
                  <FormControl className={styles.formControl}>
                    <InputLabel>Test Set</InputLabel>
                    <Select
                      labelId="testSuite-select-label"
                      id="testSuite-select"
                      data-testid="testSuite-select"
                      value={testSuiteChosen}
                      disabled={presetChosen > 0}
                      onChange={(event: React.ChangeEvent<{ value: unknown }>) => {
                        setTestSuiteChosen(event.target.value as string);
                      }}
                    >
                      {testSuites.map((testSuite: TestSuite) => {
                        return (
                          // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
                          <MenuItem key={testSuite.title} value={testSuite.id}>
                            {testSuite.title}
                          </MenuItem>
                        );
                      })}
                    </Select>
                  </FormControl>
                </Grid>
                <Grid item xs={1}>
                  <Divider orientation="vertical" className={styles.divider} />
                </Grid>
                <Grid item xs={4}>
                  <FormControl className={styles.formControl}>
                    <InputLabel>Preset Configuration</InputLabel>
                    <Select
                      labelId="preset-select-label"
                      id="preset-select"
                      value={presetChosen}
                      autoWidth={false}
                      onChange={(event: React.ChangeEvent<{ value: unknown }>) => {
                        const preset = presets[event.target.value as number];
                        setPresetChosen(event.target.value as number);
                        setTestSuiteChosen(preset.testSet);
                      }}
                    >
                      {presets.map((preset, index) => {
                        return (
                          <MenuItem key={index} value={index}>
                            {preset.name}
                          </MenuItem>
                        );
                      })}
                    </Select>
                  </FormControl>
                </Grid>
              </Grid>
              <Button
                variant="contained"
                size="large"
                color="primary"
                data-testid="go-button"
                onClick={() => createTestSession()}
              >
                GO!
              </Button>
            </Container>
          </Paper>
        </Container>
      </Container>
    </div>
  );
};

export default LandingPage;
