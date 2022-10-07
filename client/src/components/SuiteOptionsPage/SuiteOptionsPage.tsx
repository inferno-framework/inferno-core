import React, { FC, useEffect } from 'react';
import {
  FormControl,
  FormControlLabel,
  FormLabel,
  Typography,
  Button,
  Paper,
  Radio,
  RadioGroup,
  Box,
  IconButton,
  Tooltip,
} from '@mui/material';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import HelpOutlineOutlinedIcon from '@mui/icons-material/HelpOutlineOutlined';
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
  const initialSelectedSuiteOptions = testSuite?.suite_options?.map((option) => ({
    // just grab the first to start
    // perhaps choices should be persisted in the URL to make it easy to share specific options
    id: option.id,
    value: option && option.list_options && option.list_options[0].value,
  }));
  const [selectedSuiteOptions, setSelectedSuiteOptions] = React.useState<SuiteOption[]>(
    initialSelectedSuiteOptions || []
  );
  const [descriptionIsTall, setDescriptionIsTall] = React.useState<boolean>(false);
  const [minDescriptionWidth, setMinDescriptionWidth] = React.useState<number>(0);

  useEffect(() => {
    handleResize();
  });

  // Update description width on window resize
  const handleResize = () => {
    const description = document.getElementById('description-container');
    const selectionPanel = document.getElementById('selection-panel');
    if (!windowIsSmall && description) {
      setDescriptionIsTall(description.scrollHeight > description.clientHeight);
      // Minimum width if !windowIsSmall (minimum window width is 1000)
      setMinDescriptionWidth(1000 - (selectionPanel?.clientWidth || 0));
    }
  };

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

  const renderBackButton = () => {
    const returnHome = () => {
      history.push('');
    };
    return (
      <Tooltip title="Back to Suites">
        <IconButton size="small" onClick={returnHome}>
          <ArrowBackIcon fontSize="large" />
        </IconButton>
      </Tooltip>
    );
  };

  // Given a suiteOption and index i, returns a RadioGroup with a RadioButton per choice
  const renderOption = (suiteOption: SuiteOption, i: number) => {
    return (
      <FormControl fullWidth id={`suite-option-input-${i}`} key={`suite-form-control${i}`}>
        <FormLabel sx={{ display: 'flex', alignItems: 'center' }}>
          {suiteOption.title}
          {suiteOption.description && (
            <Tooltip title={suiteOption.description}>
              <HelpOutlineOutlinedIcon fontSize="small" color="secondary" sx={{ px: 0.5 }} />
            </Tooltip>
          )}
        </FormLabel>

        <RadioGroup
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
      <Box mt={6} alignItems="center" maxWidth="800px">
        <Typography
          variant="h2"
          component="h1"
          align="center"
          sx={{ color: lightTheme.palette.common.orangeDarker }}
        >
          {testSuite?.title}
        </Typography>
      </Box>

      <Box
        display="flex"
        flexWrap="wrap"
        alignItems="center"
        justifyContent="space-evenly"
        width="100%"
        sx={windowIsSmall ? { overflow: 'auto' } : { mt: 4, mb: 8, overflow: 'hidden' }}
      >
        {/* Description */}
        <Box
          id="description-container"
          display={!windowIsSmall && descriptionIsTall ? 'flex' : ''}
          flex={!windowIsSmall && descriptionIsTall ? '1 1 0' : ''}
          maxWidth={!descriptionIsTall ? `${minDescriptionWidth}px` : 'unset'}
          maxHeight="100%"
          overflow="auto"
          ml={3}
          my={3}
        >
          <Typography
            variant="h6"
            component="h2"
            px={2}
            sx={{
              wordBreak: 'break-word',
            }}
          >
            <ReactMarkdown>
              {testSuite?.suite_summary || testSuite?.description || ''}
            </ReactMarkdown>
          </Typography>
        </Box>
        {/* Selection panel */}
        <Box
          display="flex"
          justifyContent="center"
          maxHeight="100%"
          overflow="auto"
          id="selection-panel"
          p={3}
        >
          <Paper
            elevation={4}
            className={styles.optionsList}
            sx={{ width: windowIsSmall ? 'auto' : '400px' }}
          >
            <Box display="flex" alignItems="center" justifyContent="space-between" mx={1}>
              {renderBackButton()}
              <Typography variant="h4" component="h2" align="center">
                Options
              </Typography>
              {/* Spacer to center title with button */}
              <Box minWidth="45px" />
            </Box>

            <Box overflow="auto" px={4} py={2}>
              {testSuite?.suite_options ? (
                testSuite.suite_options.map((suiteOption: SuiteOption, i) =>
                  renderOption(suiteOption, i)
                )
              ) : (
                <Typography mt={2}> No options available.</Typography>
              )}
            </Box>

            <Box px={2}>
              <Button
                variant="contained"
                size="large"
                color="primary"
                fullWidth
                data-testid="go-button"
                sx={{ fontWeight: 600 }}
                onClick={() => createTestSession()}
              >
                Select Options
              </Button>
            </Box>
          </Paper>
        </Box>
      </Box>
    </Box>
  );
};

export default SuiteOptionsPage;
