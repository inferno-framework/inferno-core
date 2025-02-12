import React, { FC, useEffect } from 'react';
import { useNavigate } from 'react-router';
import { Typography, Container, Box } from '@mui/material';
import { useSnackbar } from 'notistack';
import { TestSuite, TestSession } from '~/models/testSuiteModels';
import {
  ListOptionSelection,
  RadioOptionSelection,
  isListOptionSelection,
} from '~/models/selectionModels';
import { postTestSessions } from '~/api/TestSessionApi';
import { getStaticPath } from '~/api/infernoApiService';
import { useAppStore } from '~/store/app';
import infernoLogo from '~/images/inferno_logo.png';
import MetaTags from '~/components/_common/MetaTags';
import SelectionPanel from '~/components/_common/SelectionPanel/SelectionPanel';
import lightTheme from '~/styles/theme';
import useStyles from './styles';
import SelectionSkeleton from '../Skeletons/SelectionSkeletion';

export interface LandingPageProps {
  testSuites: TestSuite[] | undefined;
}

const LandingPage: FC<LandingPageProps> = ({ testSuites }) => {
  const navigate = useNavigate();
  const { classes } = useStyles();
  const { enqueueSnackbar } = useSnackbar();
  const [testSuiteChosen, setTestSuiteChosen] = React.useState<ListOptionSelection>('');
  const windowIsSmall = useAppStore((state) => state.windowIsSmall);

  useEffect(() => {
    if (testSuites?.length === 1) {
      setTestSuiteChosen(testSuites[0].id);
      startTestingClick(testSuites[0]);
    }
  }, []);

  const setSelected = (selection: ListOptionSelection | RadioOptionSelection[]) => {
    // Check if list option to avoid type errors
    if (isListOptionSelection(selection)) setTestSuiteChosen(selection);
  };

  const startTestingClick = (suite?: TestSuite) => {
    if (suite && suite.suite_options && suite.suite_options.length > 0) {
      navigate(`${suite.id}`);
    } else if ((suite && suite?.id) || testSuiteChosen) {
      postTestSessions(suite?.id || testSuiteChosen, null, null)
        .then((testSession: TestSession | null) => {
          if (testSession && testSession.test_suite) {
            navigate(
              `/${testSession.test_suite_id}/${testSession.id}#${testSession.test_suite_id}`,
            );
          }
        })
        .catch((e: Error) => {
          enqueueSnackbar(`Error while creating test session: ${e.message}`, { variant: 'error' });
        });
    } else {
      enqueueSnackbar(`No test suite selected.`, { variant: 'error' });
    }
  };

  return (
    <Container
      maxWidth={false}
      role="main"
      className={classes.main}
      sx={
        windowIsSmall
          ? {}
          : {
              minHeight: '400px',
              maxHeight: '100vh',
              py: 10,
            }
      }
    >
      <MetaTags
        title="Inferno Test Session"
        description="Test your server's conformance to authentication, authorization, and FHIR content standards."
      />
      <Box
        display="flex"
        flexDirection="column"
        justifyContent={windowIsSmall ? 'center' : 'flex-end'}
        alignItems="center"
        overflow="initial"
        minHeight="300px"
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
      </Box>
      <Box
        display="flex"
        flexDirection="column"
        justifyContent="flex-start"
        alignItems="center"
        overflow="initial"
        width="100%"
        minHeight="200px"
        py={4}
        sx={{ backgroundColor: lightTheme.palette.common.grayLight }}
      >
        {testSuites ? (
          <SelectionPanel
            title="Test Suites"
            options={(testSuites || []).sort(
              (testSuite1: TestSuite, testSuite2: TestSuite): number =>
                testSuite1.title.localeCompare(testSuite2.title),
            )}
            setSelection={setSelected}
            submitAction={() =>
              startTestingClick(
                testSuites?.find((suite: TestSuite) => suite.id === testSuiteChosen),
              )
            }
            submitText="Select Suite"
          />
        ) : (
          <SelectionSkeleton />
        )}
      </Box>
    </Container>
  );
};

export default LandingPage;
