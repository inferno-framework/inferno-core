import React, { FC, useEffect } from 'react';
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
import { useNavigate } from 'react-router-dom';
import { postTestSessions } from 'api/TestSessionApi';
import { useAppStore } from '~/store/app';
import { getStaticPath } from '~/api/infernoApiService';
import lightTheme from '~/styles/theme';
import infernoLogo from '~/images/inferno_logo.png';
import { useSnackbar } from 'notistack';

export interface LandingPageProps {
  testSuites: TestSuite[] | undefined;
}

const LandingPage: FC<LandingPageProps> = ({ testSuites }) => {
  const navigate = useNavigate();
  const { classes } = useStyles();
  const { enqueueSnackbar } = useSnackbar();
  const [testSuiteChosen, setTestSuiteChosen] = React.useState('');
  const windowIsSmall = useAppStore((state) => state.windowIsSmall);

  useEffect(() => {
    if (testSuites?.length === 1) {
      setTestSuiteChosen(testSuites[0].id);
      startTestingClick(testSuites[0]);
    }
  }, []);

  const startTestingClick = (suite?: TestSuite) => {
    if (suite && suite.suite_options && suite.suite_options.length > 0) {
      navigate(`${suite.id}`);
    } else if ((suite && suite?.id) || testSuiteChosen) {
      postTestSessions(suite?.id || testSuiteChosen, null, null)
        .then((testSession: TestSession | null) => {
          if (testSession && testSession.test_suite) {
            navigate(`/${testSession.test_suite_id}/${testSession.id}`);
          }
        })
        .catch((e: Error) => {
          enqueueSnackbar(`Error while creating test session: ${e.message}`, { variant: 'error' });
        });
    } else {
      enqueueSnackbar(`No test suite selected.`, { variant: 'error' });
    }
  };

  const renderOption = (testSuite: TestSuite) => {
    return (
      // Use li to resolve a11y error
      <li key={testSuite.id}>
        <ListItemButton
          data-testid="testing-suite-option"
          selected={testSuiteChosen === testSuite.id}
          onClick={() => setTestSuiteChosen(testSuite.id)}
          classes={{ selected: classes.selectedItem }}
        >
          <ListItemText primary={testSuite.title} />
          {/* {testSuiteChosen === testSuite.id && <></>} */}
        </ListItemButton>
      </li>
    );
  };

  return (
    <Container
      maxWidth={false}
      role="main"
      className={classes.main}
      sx={
        !windowIsSmall
          ? {
              minHeight: '400px',
              maxHeight: '100vh',
              py: 10,
            }
          : {}
      }
    >
      <Box
        display="flex"
        flexDirection="column"
        justifyContent={windowIsSmall ? 'center' : 'flex-end'}
        alignItems="center"
        overflow="initial"
        height="45%"
        minHeight="200px"
        pb={windowIsSmall ? 0 : 2}
        px={2}
      >
        <Box my={2} alignItems="center" maxWidth="800px">
          <Box display="flex" alignItems="center" justifyContent="center">
            <img
              src={getStaticPath(infernoLogo as string)}
              alt="Inferno Logo"
              style={{ height: windowIsSmall ? '5em' : '8em' }}
            />
          </Box>
          <Typography
            variant="h4"
            component="h1"
            align="center"
            sx={{
              color: lightTheme.palette.common.grayDark,
              fontSize: windowIsSmall ? '2rem' : 'auto',
              fontWeight: 'bolder',
            }}
          >
            FHIR Testing with Inferno
          </Typography>
        </Box>
        <Box mb={2} alignItems="center" maxWidth="600px">
          <Typography
            variant="h5"
            component="h2"
            align="center"
            sx={{
              fontSize: windowIsSmall ? '1.2rem' : 'auto',
            }}
          >
            Test your server's conformance to authentication, authorization, and FHIR content
            standards.
          </Typography>
        </Box>
        {/* <Paper
          elevation={4}
          className={classes.optionsList}
          sx={{ width: windowIsSmall ? 'auto' : '400px', maxWidth: '400px' }}
        >
          <Typography
            variant="h4"
            component="h2"
            align="center"
            sx={{ fontSize: windowIsSmall ? '1.8rem' : 'auto' }}
          >
            Test Suites
          </Typography>
          <Box>
            <List>
              {testSuites ? (
                testSuites
                  .sort((testSuite1: TestSuite, testSuite2: TestSuite): number =>
                    testSuite1.title.localeCompare(testSuite2.title)
                  )
                  .map((testSuite: TestSuite) => renderOption(testSuite))
              ) : (
                <Typography my={2}> No suites available.</Typography>
              )}
            </List>
          </Box>
          <Button
            variant="contained"
            size="large"
            color="primary"
            fullWidth
            disabled={!testSuiteChosen}
            data-testid="go-button"
            sx={{ fontWeight: 600 }}
            onClick={() =>
              startTestingClick(
                testSuites?.find((suite: TestSuite) => suite.id === testSuiteChosen)
              )
            }
          >
            Select Suite
          </Button>
        </Paper> */}
      </Box>
      <Box
        display="flex"
        flexDirection="column"
        justifyContent="flex-start"
        alignItems="center"
        overflow="initial"
        height="55%"
        width="100%"
        minHeight="200px"
        py={2}
        sx={{ backgroundColor: lightTheme.palette.common.gray }}
      >
        <Paper
          elevation={4}
          className={classes.optionsList}
          sx={{ width: windowIsSmall ? 'auto' : '400px', maxWidth: '400px' }}
        >
          <Typography
            variant="h4"
            component="h2"
            align="center"
            sx={{ fontSize: windowIsSmall ? '1.8rem' : 'auto' }}
          >
            Test Suites
          </Typography>
          <Box>
            <List>
              {testSuites ? (
                testSuites
                  .sort((testSuite1: TestSuite, testSuite2: TestSuite): number =>
                    testSuite1.title.localeCompare(testSuite2.title)
                  )
                  .map((testSuite: TestSuite) => renderOption(testSuite))
              ) : (
                <Typography my={2}> No suites available.</Typography>
              )}
            </List>
          </Box>
          <Button
            variant="contained"
            size="large"
            color="primary"
            fullWidth
            disabled={!testSuiteChosen}
            data-testid="go-button"
            sx={{ fontWeight: 600 }}
            onClick={() =>
              startTestingClick(
                testSuites?.find((suite: TestSuite) => suite.id === testSuiteChosen)
              )
            }
          >
            Select Suite
          </Button>
        </Paper>
      </Box>
    </Container>
  );
};

export default LandingPage;
