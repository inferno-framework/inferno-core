import React, { FC, useEffect, useRef } from 'react';
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
import { useNavigate, useParams } from 'react-router-dom';
import { postTestSessions } from '~/api/TestSessionApi';
import { TestSuite, TestSession, SuiteOption } from '~/models/testSuiteModels';
import ReactMarkdown from 'react-markdown';
import { useAppStore } from '~/store/app';
import lightTheme from '~/styles/theme';
import { useSnackbar } from 'notistack';

export interface SuiteOptionsPageProps {
  testSuite?: TestSuite;
}

const SuiteOptionsPage: FC<SuiteOptionsPageProps> = ({ testSuite }) => {
  const { enqueueSnackbar } = useSnackbar();
  const windowIsSmall = useAppStore((state) => state.windowIsSmall);
  const smallWindowThreshold = useAppStore((state) => state.smallWindowThreshold);
  const styles = useStyles();
  const navigate = useNavigate();
  const { test_suite_id } = useParams<{ test_suite_id: string }>();
  const initialSelectedSuiteOptions = testSuite?.suite_options?.map((option) => ({
    // just grab the first to start
    // perhaps choices should be persisted in the URL to make it easy to share specific options
    id: option.id,
    value: option && option.list_options ? option.list_options[0].value : '',
  }));
  const [selectedSuiteOptions, setSelectedSuiteOptions] = React.useState<SuiteOption[]>(
    initialSelectedSuiteOptions || []
  );
  const [descriptionWidth, setDescriptionWidth] = React.useState<string>('');
  const selectionPanel = useRef<HTMLElement>(null);

  useEffect(() => {
    if (
      // If no suite or no options and no description, then start a test session
      !testSuite ||
      (!testSuite.suite_summary &&
        (!testSuite.suite_options || testSuite.suite_options.length === 0))
    ) {
      createTestSession(null);
    }
  }, []);

  useEffect(() => {
    getDescriptionWidth();
  }, [windowIsSmall]);

  const getDescriptionWidth = () => {
    if (windowIsSmall) {
      setDescriptionWidth('100%');
    } else if (selectionPanel.current) {
      setDescriptionWidth(`${smallWindowThreshold - (selectionPanel.current.clientWidth || 0)}px`);
    }
  };

  const changeSuiteOption = (option_id: string, value: string): void => {
    const newOptions: SuiteOption[] = selectedSuiteOptions.map((option) =>
      option.id === option_id ? { id: option.id, value: value } : { ...option }
    );
    setSelectedSuiteOptions(newOptions);
  };

  const createTestSession = (options: SuiteOption[] | null = null): void => {
    if (!test_suite_id) return;
    postTestSessions(test_suite_id, null, options)
      .then((testSession: TestSession | null) => {
        if (testSession && testSession.test_suite) {
          navigate(testSession.test_suite_id + '/' + testSession.id);
        }
      })
      .catch((e: Error) => {
        enqueueSnackbar(`Error while creating test session: ${e.message}`, { variant: 'error' });
      });
  };

  const renderBackButton = () => {
    const returnHome = () => {
      navigate('/');
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
      minHeight="600px"
      height="100%"
      maxHeight="100vh"
      role="main"
    >
      {/* Title */}
      <Box alignItems="center" maxWidth="800px" sx={windowIsSmall ? { m: 2 } : { mt: 6 }}>
        <Typography
          variant="h2"
          component="h1"
          align="center"
          sx={{
            color: lightTheme.palette.common.orangeDarker,
            fontSize: windowIsSmall ? '2rem' : 'auto',
          }}
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
        sx={windowIsSmall ? { overflow: 'auto' } : { mt: 4, pb: 8, overflow: 'hidden' }}
      >
        {/* Description */}
        <Box
          maxWidth={descriptionWidth}
          maxHeight={windowIsSmall ? 'none' : '100%'}
          overflow="auto"
          my={3}
        >
          <Typography
            variant="h6"
            component="h2"
            pr={2}
            pl={5}
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
          ref={selectionPanel}
          p={3}
        >
          <Paper
            elevation={4}
            className={styles.optionsList}
            sx={{ width: windowIsSmall ? 'auto' : '400px', maxWidth: '400px' }}
          >
            <Box display="flex" alignItems="center" justifyContent="space-between" mx={1}>
              {renderBackButton()}
              <Typography
                variant="h4"
                component="h2"
                align="center"
                sx={{
                  fontSize: windowIsSmall ? '1.8rem' : 'auto',
                }}
              >
                Options
              </Typography>
              {/* Spacer to center title with button */}
              <Box minWidth="45px" />
            </Box>

            <Box overflow="auto" px={4} pt={2}>
              {testSuite?.suite_options ? (
                testSuite?.suite_options.map((suiteOption: SuiteOption, i) =>
                  renderOption(suiteOption, i)
                )
              ) : (
                <Typography mt={2}> No options available.</Typography>
              )}
            </Box>

            <Box px={2} pt={2}>
              <Button
                variant="contained"
                size="large"
                color="primary"
                fullWidth
                data-testid="go-button"
                sx={{ fontWeight: 600 }}
                onClick={() => createTestSession(selectedSuiteOptions)}
              >
                Start Testing
              </Button>
            </Box>
          </Paper>
        </Box>
      </Box>
    </Box>
  );
};

export default SuiteOptionsPage;
