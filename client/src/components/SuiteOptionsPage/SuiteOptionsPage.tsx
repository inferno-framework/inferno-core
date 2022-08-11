import React, { FC } from 'react';
import {
  FormControl,
  FormControlLabel,
  FormLabel,
  Typography,
  Container,
  Button,
  Paper,
  Radio,
  RadioGroup,
  Box,
} from '@mui/material';
import useStyles from './styles';
import { useHistory, useParams } from 'react-router-dom';
import { postTestSessions } from '~/api/TestSessionApi';
import { TestSuite, TestSession, SuiteOption } from '~/models/testSuiteModels';
import ReactMarkdown from 'react-markdown';
import { useAppStore } from '~/store/app';
import lightTheme from '~/styles/theme';

export interface SuiteOptionsPageProps {
  testSuites: TestSuite[] | undefined;
}

const SuiteOptionsPage: FC<SuiteOptionsPageProps> = ({ testSuites }) => {
  const windowIsSmall = useAppStore((state) => state.windowIsSmall);
  const styles = useStyles();
  const history = useHistory();

  const { test_suite_id } = useParams<{ test_suite_id: string }>();

  const testSuite = testSuites?.find((suite: TestSuite) => suite.id === test_suite_id);

  // just grab the first to start
  // perhaps choices should be persisted in the URL to make it easy to share specific
  // options
  const initialSelectedSuiteOptions = testSuite?.suite_options?.map((option) => ({
    id: option.id,
    value: option && option.list_options && option.list_options[0].value,
  }));

  const [selectedSuiteOptions, setSelectedSuiteOptions] = React.useState<SuiteOption[]>(
    initialSelectedSuiteOptions || []
  );

  function changeSuiteOption(option_id: string, value: string): void {
    const newOptions: SuiteOption[] = selectedSuiteOptions.map((option) =>
      option.id === option_id ? { id: option.id, value: value } : { ...option }
    );
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

  // Given a suiteOption and index i, returns a RadioGroup with a RadioButton per choice
  const renderOption = (suiteOption: SuiteOption, i: number) => {
    return (
      <FormControl fullWidth id={`suite-option-input-${i}`} key={`suite-form-control${i}`}>
        <FormLabel>{suiteOption.title}</FormLabel>
        <RadioGroup
          row
          aria-label={`suite-option-group-${suiteOption.id}`}
          defaultValue={
            suiteOption.list_options &&
            suiteOption.list_options.length &&
            suiteOption.list_options[0].value
          }
          name={`suite-option-group-${suiteOption.id}`}
        >
          {suiteOption?.list_options?.map((choice, k) => (
            <FormControlLabel
              value={choice.value}
              control={<Radio size="small" />}
              label={choice.label}
              key={`radio-button-${k}`}
              onClick={() => {
                changeSuiteOption(suiteOption.id, choice.value);
              }}
            />
          ))}
        </RadioGroup>
      </FormControl>
    );
  };

  return (
    <Box
      display="flex"
      alignItems="center"
      justifyContent="center"
      flexDirection="column"
      height="100%"
      maxHeight="100vh"
      role="main"
    >
      {/* Title */}
      <Box py={6} sx={{ backgroundColor: lightTheme.palette.common.orangeLightest }}>
        <Typography
          variant="h2"
          component="h1"
          align="center"
          sx={{ color: lightTheme.palette.common.orangeDarker }}
        >
          {testSuite?.title}
        </Typography>
      </Box>

      <Container
        maxWidth="lg"
        className={styles.main}
        sx={{ overflow: windowIsSmall ? 'auto' : 'hidden' }}
      >
        {/* Description */}
        <Box maxHeight="100%" height="100%" maxWidth="440px" overflow="auto">
          <Typography variant="h6" component="h2">
            <ReactMarkdown>{testSuite?.description || ''}</ReactMarkdown>
          </Typography>
        </Box>
        {/* Selection panel */}
        <Box display="flex" justifyContent="center" maxHeight="100%" overflow="auto">
          <Paper
            elevation={4}
            className={styles.optionsList}
            sx={{ width: windowIsSmall ? 'auto' : '400px' }}
          >
            <Typography variant="h4" component="h2" align="center" my={2}>
              Select Options
            </Typography>
            <Box overflow="scroll">
              {testSuite?.suite_options ? (
                testSuite.suite_options.map((suiteOption: SuiteOption, i) =>
                  renderOption(suiteOption, i)
                )
              ) : (
                <Typography mt={2}> No options available.</Typography>
              )}
            </Box>
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
        </Box>
      </Container>
    </Box>
  );
};

export default SuiteOptionsPage;
