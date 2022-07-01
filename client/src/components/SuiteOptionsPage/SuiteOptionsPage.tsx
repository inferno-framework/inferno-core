import React, { FC } from 'react';
import {
  FormControl,
  FormControlLabel,
  FormLabel,
  Typography,
  Container,
  Button,
  Paper,
  List,
  Grid,
  Radio,
  RadioGroup
} from '@mui/material';
import useStyles from './styles';
import { useHistory, useParams } from 'react-router-dom';
import { postTestSessions } from '~/api/TestSessionApi';
import { TestSuite, TestSession, SuiteOption } from '~/models/testSuiteModels';
import ReactMarkdown from 'react-markdown';

export interface SuiteOptionsPageProps {
  testSuites: TestSuite[] | undefined;
}

const SuiteOptionsPage: FC<SuiteOptionsPageProps> = ({ testSuites }) => {
  const styles = useStyles();
  const history = useHistory();

  const { test_suite_id } = useParams<{ test_suite_id: string }>();

  const testSuite = testSuites?.find((suite: TestSuite) => suite.id == test_suite_id);
  const initialSelectedSuiteOptions = (testSuite?.suite_options || []).map( (option) => {
    return {...option, value: option && option.list_options && option.list_options[0].value}
  });

  const [selectedSuiteOptions, setSelectedSuiteOptions] = React.useState<SuiteOption[]>(initialSelectedSuiteOptions);

  function changeSuiteOption(option_id: string, value: string): void {
    const newOptions: SuiteOption[] = selectedSuiteOptions.map( (option) => {
      if(option.id == option_id){
        return {...option, value: value}
      }
      return {...option}
    });
    setSelectedSuiteOptions(newOptions);
  }

  function createTestSession(): void {
    postTestSessions(test_suite_id, null, selectedSuiteOptions)
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
    <Container maxWidth="lg" className={styles.main} role="main">
      <Grid container spacing={6}>
        <Grid container item xs={6}>
          <Grid item>
            <Typography variant="h2" component="h1">
              { testSuite?.title }
            </Typography>
            <Typography variant="h5" component="h2">
              <ReactMarkdown>{testSuite?.description || ''}</ReactMarkdown>
            </Typography>
          </Grid>
        </Grid>
        <Grid container item xs={6}>
          <Grid item>
            <Paper elevation={4} className={styles.startTesting}>
              <Typography variant="h4" component="h2" align="center">
                Select Options
              </Typography>
                {testSuite?.suite_options?.map((suiteOption: SuiteOption, i) => (
                <FormControl
                  fullWidth
                  id={`suite-option-input-${i}`}
                  key={`suite-form-control${i}`}>
                  <FormLabel>{suiteOption.title}</FormLabel>
                  <RadioGroup
                    row
                    aria-label={`suite-option-group-${suiteOption.id}`}
                    defaultValue={suiteOption.list_options && suiteOption.list_options.length && suiteOption.list_options[0].value}
                    name={`suite-option-group-${suiteOption.id}`}>
                    {suiteOption && suiteOption.list_options && suiteOption.list_options.map((choice, k) => (
                    <FormControlLabel 
                      value={choice.value}
                      control={<Radio size="small" />}
                      label={choice.label} 
                      key={`radio-button-${k}`}
                      onClick = {()=> {changeSuiteOption(suiteOption.id, choice.value)}} />
                    ))}
                  </RadioGroup>
                </FormControl>
                ))}

              <List>
              </List>
              <Button
                variant="contained"
                size="large"
                color="primary"
                fullWidth
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

export default SuiteOptionsPage;
