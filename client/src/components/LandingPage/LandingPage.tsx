import React, { FC, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { Typography, Container, Box } from '@mui/material';
import { useSnackbar } from 'notistack';
import { TestSuite, TestSession, SuiteOption } from '~/models/testSuiteModels';
import {
  ListOptionSelection,
  RadioOptionSelection,
  isListOptionSelection,
  isRadioOptionSelection,
} from '~/models/selectionModels';
import { postTestSessions } from '~/api/TestSessionApi';
import { getStaticPath } from '~/api/infernoApiService';
import { useAppStore } from '~/store/app';
import infernoLogo from '~/images/inferno_logo.png';
import SelectionPanel from '~/components/_common/SelectionPanel/SelectionPanel';
import lightTheme from '~/styles/theme';
import useStyles from './styles';
import { ReactMarkdown } from 'react-markdown/lib/react-markdown';

export interface LandingPageProps {
  testSuites: TestSuite[] | undefined;
}

const LandingPage: FC<LandingPageProps> = ({ testSuites }) => {
  const navigate = useNavigate();
  const { classes } = useStyles();
  const { enqueueSnackbar } = useSnackbar();
  // const { test_suite_id } = useParams<{ test_suite_id: string }>();
  const [selectedTestSuiteId, setSelectedTestSuiteId] = React.useState<ListOptionSelection>('');
  const selectedTestSuite = testSuites?.find(
    (suite: TestSuite) => suite.id === selectedTestSuiteId
  );
  const initialSelectedSuiteOptions = selectedTestSuite?.suite_options?.map((option) => ({
    // just grab the first to start
    // perhaps choices should be persisted in the URL to make it easy to share specific options
    id: option.id,
    value: option && option.list_options ? option.list_options[0].value : '',
  }));
  const [selectedSuiteOptions, setSelectedSuiteOptions] = React.useState<SuiteOption[]>(
    initialSelectedSuiteOptions || []
  );
  const [showSuites, setShowSuites] = React.useState<boolean>(true);
  const windowIsSmall = useAppStore((state) => state.windowIsSmall);
  const smallWindowThreshold = useAppStore((state) => state.smallWindowThreshold);
  const [descriptionWidth, setDescriptionWidth] = React.useState<string>('');
  const selectionPanel = useRef<HTMLElement>(null);

  useEffect(() => {
    if (testSuites?.length === 1) {
      setSelectedTestSuiteId(testSuites[0].id);
      startTestingClick(testSuites[0]);
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

  const setSuiteSelected = (selection: ListOptionSelection | RadioOptionSelection[] | null) => {
    // Check if list option to avoid type errors
    if (selection && isListOptionSelection(selection)) setSelectedTestSuiteId(selection);
  };

  const setOptionsSelected = (selection: ListOptionSelection | RadioOptionSelection[] | null) => {
    // Check if radio option to avoid type errors
    if (selection && isRadioOptionSelection(selection)) setSelectedSuiteOptions(selection);
  };

  const startTestingClick = (suite?: TestSuite) => {
    if (suite && suite.suite_options && suite.suite_options.length > 0) {
      // navigate(`${suite.id}`);
      setShowSuites(false);
    } else if ((suite && suite?.id) || selectedTestSuiteId) {
      postTestSessions(suite?.id || selectedTestSuiteId, null, null)
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

  const createTestSession = (options: SuiteOption[] | null = null): void => {
    if (!selectedTestSuiteId) return;
    postTestSessions(selectedTestSuiteId, null, options)
      .then((testSession: TestSession | null) => {
        if (testSession && testSession.test_suite) {
          navigate(`/${testSession.test_suite_id}/${testSession.id}`);
        }
      })
      .catch((e: Error) => {
        enqueueSnackbar(`Error while creating test session: ${e.message}`, { variant: 'error' });
      });
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
              flexDirection: 'column',
              minHeight: '500px',
              py: 10,
            }
      }
    >
      <Box
        display="flex"
        flexDirection="column"
        justifyContent="center"
        alignItems="center"
        maxWidth={windowIsSmall ? '100%' : '50%'}
        maxHeight={windowIsSmall ? 'none' : '100%'}
        minHeight={windowIsSmall ? 'none' : '100%'}
        overflow="auto"
        my={3}
      >
        <Box
          display="flex"
          alignItems="center"
          maxWidth={descriptionWidth}
          maxHeight={windowIsSmall ? 'none' : '100%'}
          my={2}
        >
          <Box display="flex" flexDirection="column" alignItems="center" justifyContent="center">
            <img
              src={getStaticPath(infernoLogo as string)}
              alt="Inferno Logo"
              style={{ height: windowIsSmall ? '5em' : '8em' }}
            />
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
        </Box>
        <Box display="flex" alignItems="center" maxWidth={descriptionWidth} mb={2} px={2}>
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
        <Box
          display="flex"
          justifyContent="center"
          maxWidth={descriptionWidth}
          overflow="auto"
          mb={2}
          px={2}
        >
          <Typography
            variant="h6"
            component="h2"
            sx={{
              wordBreak: 'break-word',
            }}
          >
            <ReactMarkdown>
              {selectedTestSuite?.suite_summary || selectedTestSuite?.description || ''}
            </ReactMarkdown>
          </Typography>
        </Box>
      </Box>
      <Box
        display="flex"
        height={windowIsSmall ? 'unset' : '100%'}
        width={windowIsSmall ? '100%' : 'unset'}
        maxWidth={windowIsSmall ? '100%' : '50%'}
        justifyContent="center"
        alignItems="center"
        sx={{ backgroundColor: lightTheme.palette.common.gray }}
        ref={selectionPanel}
      >
        <Box display="flex" justifyContent="center" maxHeight={'calc(100% - 24px)'} mx={3}>
          {showSuites ? (
            <SelectionPanel
              title="Test Suites"
              options={(testSuites || []).sort(
                (testSuite1: TestSuite, testSuite2: TestSuite): number =>
                  testSuite1.title.localeCompare(testSuite2.title)
              )}
              setSelection={setSuiteSelected}
              submitAction={() =>
                startTestingClick(
                  testSuites?.find((suite: TestSuite) => suite.id === selectedTestSuiteId)
                )
              }
              submitText="Select Suite"
            />
          ) : (
            <SelectionPanel
              title="Options"
              options={selectedTestSuite?.suite_options || []}
              setSelection={setOptionsSelected}
              showBackButton={true}
              backTooltipText="Back to Suites"
              backClickHandler={() => {
                setShowSuites(true);
                setSelectedTestSuiteId('');
              }}
              submitAction={() => createTestSession(selectedSuiteOptions)}
              submitText="Start Testing"
            />
          )}
        </Box>
      </Box>
    </Container>
  );
};

export default LandingPage;
