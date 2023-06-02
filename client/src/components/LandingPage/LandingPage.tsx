import React, { FC, useEffect, useRef } from 'react';
import { useLocation, useNavigate, useParams } from 'react-router-dom';
import { Typography, Container, Box } from '@mui/material';
import { ReactMarkdown } from 'react-markdown/lib/react-markdown';
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

export interface LandingPageProps {
  testSuites: TestSuite[] | undefined;
}

const LandingPage: FC<LandingPageProps> = ({ testSuites }) => {
  const location = useLocation();
  const navigate = useNavigate();
  const { classes } = useStyles();
  const { enqueueSnackbar } = useSnackbar();
  const { test_suite_id } = useParams<{ test_suite_id: string }>();

  /* Selections and state */
  const [selectedTestSuiteId, setSelectedTestSuiteId] = React.useState<ListOptionSelection>(
    test_suite_id || ''
  );
  const selectedTestSuite = testSuites?.find(
    (suite: TestSuite) => suite.id === selectedTestSuiteId
  );
  const defaultSuiteOptions = selectedTestSuite?.suite_options?.map((option) => ({
    // just grab the first to start
    // perhaps choices should be persisted in the URL to make it easy to share specific options
    id: option.id,
    value: option && option.list_options ? option.list_options[0].value : '',
  }));
  const [selectedSuiteOptions, setSelectedSuiteOptions] = React.useState<SuiteOption[]>(
    defaultSuiteOptions || []
  );
  const [showLandingPage, setShowLandingPage] = React.useState<boolean>(true);
  const [showSuiteSelection, setShowSuiteSelection] = React.useState<boolean>(true);

  /* CSS variables */
  const windowIsSmall = useAppStore((state) => state.windowIsSmall);
  const smallWindowThreshold = useAppStore((state) => state.smallWindowThreshold);
  const [descriptionWidth, setDescriptionWidth] = React.useState<string>('');
  const selectionPanel = useRef<HTMLElement>(null);

  useEffect(() => {
    if (
      // If no options and no description and suite is selected on load, start a test session
      selectedTestSuite &&
      !selectedTestSuite?.suite_summary &&
      !selectedTestSuite?.description &&
      (!selectedTestSuite?.suite_options || selectedTestSuite?.suite_options.length === 0)
    ) {
      setShowLandingPage(false);
      createTestSession(null);
    } else if (
      selectedTestSuite &&
      selectedTestSuite?.suite_options &&
      selectedTestSuite?.suite_options.length !== 0
    ) {
      // If options exist and suite is selected on load, set selection panel to show options
      setShowSuiteSelection(false);
    } else if (testSuites?.length === 1) {
      // If only one suite, then default to that suite
      setSelectedTestSuiteId(testSuites[0].id);
      startTestingClick(testSuites[0]);
    }
  }, []);

  useEffect(() => {
    // Handle browser back and forward button behavior
    setSelectedTestSuiteId(test_suite_id || '');
  }, [location]);

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

  // Set selected suite ID and update URL
  const setSuiteSelected = (selection: ListOptionSelection | RadioOptionSelection[] | null) => {
    // Check if list option to avoid type errors, allow empty string
    if (selection !== null && selection !== undefined && isListOptionSelection(selection)) {
      setSelectedTestSuiteId(selection);
      navigate(`/${selection}`);
    }
  };

  // Set options radio selections
  const setOptionsSelected = (selection: ListOptionSelection | RadioOptionSelection[] | null) => {
    // Check if radio option to avoid type errors
    if (selection && isRadioOptionSelection(selection)) setSelectedSuiteOptions(selection);
  };

  // Either show options or start test session
  const startTestingClick = (suite?: TestSuite) => {
    if (suite && suite.suite_options && suite.suite_options.length > 0) {
      setShowSuiteSelection(false);
    } else if ((suite && suite?.id) || selectedTestSuiteId) {
      setShowLandingPage(false);
      createTestSession(null);
    } else {
      enqueueSnackbar(`No test suite selected.`, { variant: 'error' });
    }
  };

  // Start test session
  const createTestSession = (options: SuiteOption[] | null = null): void => {
    if (!selectedTestSuiteId) return;
    postTestSessions(selectedTestSuiteId, null, options)
      .then((testSession: TestSession | null) => {
        console.log(testSession);

        if (testSession && testSession.test_suite) {
          navigate(`/${testSession.test_suite_id}/${testSession.id}`);
        }
      })
      .catch((e: Error) => {
        enqueueSnackbar(`Error while creating test session: ${e.message}`, { variant: 'error' });
      });
  };

  if (!showLandingPage) return <></>;
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
        className={classes.flexContainer}
        maxWidth={windowIsSmall ? '100%' : '50%'}
        maxHeight={windowIsSmall ? 'none' : '100%'}
        minHeight={windowIsSmall ? 'unset' : '100%'}
        overflow="auto"
        my={3}
      >
        <Box
          className={classes.flexContainer}
          maxWidth={descriptionWidth}
          maxHeight={windowIsSmall ? 'none' : '100%'}
          my={2}
        >
          <Box className={classes.flexContainer}>
            <img
              src={getStaticPath(infernoLogo as string)}
              alt="Inferno Logo"
              style={{ height: windowIsSmall ? '5em' : '8em' }}
            />
            <Typography
              variant="h4"
              component="h1"
              align="center"
              className={classes.title}
              sx={{ fontSize: windowIsSmall ? '2rem' : 'auto' }}
            >
              FHIR Testing with Inferno
            </Typography>
          </Box>
        </Box>
        {selectedTestSuite?.suite_summary || selectedTestSuite?.description ? (
          <Box maxWidth={descriptionWidth} overflow="auto" mb={2} px={2}>
            <Typography variant="h6" component="h2" sx={{ wordBreak: 'break-word' }}>
              <ReactMarkdown>
                {selectedTestSuite?.suite_summary || selectedTestSuite?.description || ''}
              </ReactMarkdown>
            </Typography>
          </Box>
        ) : (
          <Box className={classes.flexContainer} maxWidth={descriptionWidth} mb={2} px={2}>
            <Typography
              variant="h5"
              component="h2"
              align="center"
              sx={{ fontSize: windowIsSmall ? '1.2rem' : 'revert' }}
            >
              Test your server's conformance to authentication, authorization, and FHIR content
              standards.
            </Typography>
          </Box>
        )}
      </Box>
      <Box
        className={classes.flexContainer}
        height={windowIsSmall ? 'unset' : '100%'}
        width={windowIsSmall ? '100%' : 'unset'}
        maxWidth={windowIsSmall ? '100%' : '50%'}
        sx={{ backgroundColor: lightTheme.palette.common.gray }}
        ref={selectionPanel}
      >
        <Box display="flex" justifyContent="center" maxHeight={'calc(100% - 24px)'} mx={3}>
          {showSuiteSelection ? (
            // Suite selection
            <SelectionPanel
              title="Test Suites"
              options={(testSuites || []).sort(
                (testSuite1: TestSuite, testSuite2: TestSuite): number =>
                  testSuite1.title.localeCompare(testSuite2.title)
              )}
              selection={selectedTestSuiteId}
              setSelection={setSuiteSelected}
              submitAction={() =>
                startTestingClick(
                  testSuites?.find((suite: TestSuite) => suite.id === selectedTestSuiteId)
                )
              }
              submitText="Select Suite"
            />
          ) : (
            // Options selection
            <SelectionPanel
              title="Options"
              options={selectedTestSuite?.suite_options || []}
              setSelection={setOptionsSelected}
              showBackButton={true}
              backTooltipText="Back to Suites"
              backClickHandler={() => {
                setShowSuiteSelection(true);
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
