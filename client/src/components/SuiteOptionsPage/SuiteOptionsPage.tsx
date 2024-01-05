import React, { FC, useEffect, useRef } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { Typography, Box, Container } from '@mui/material';
import ReactMarkdown from 'react-markdown';
import { useSnackbar } from 'notistack';
import { postTestSessions } from '~/api/TestSessionApi';
import { TestSuite, TestSession, SuiteOption } from '~/models/testSuiteModels';
import {
  ListOptionSelection,
  RadioOptionSelection,
  isRadioOptionSelection,
} from '~/models/selectionModels';
import { useAppStore } from '~/store/app';
import lightTheme from '~/styles/theme';
import SelectionPanel from '~/components/_common/SelectionPanel/SelectionPanel';
import useStyles from './styles';
import { basePath } from '~/api/infernoApiService';

export interface SuiteOptionsPageProps {
  testSuite?: TestSuite;
}

const SuiteOptionsPage: FC<SuiteOptionsPageProps> = ({ testSuite }) => {
  const navigate = useNavigate();
  const { classes } = useStyles();
  const { enqueueSnackbar } = useSnackbar();
  const windowIsSmall = useAppStore((state) => state.windowIsSmall);
  const smallWindowThreshold = useAppStore((state) => state.smallWindowThreshold);
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
  const [showPage, setShowPage] = React.useState<boolean>(false);
  const selectionPanel = useRef<HTMLElement>(null);

  useEffect(() => {
    if (
      // If no suite or no options, then start a test session
      !testSuite?.suite_summary &&
      (!testSuite?.suite_options || testSuite?.suite_options.length === 0)
    ) {
      createTestSession(null);
    } else {
      setShowPage(true);
      getDescriptionWidth();
    }
  }, []);

  useEffect(() => {
    getDescriptionWidth();
  }, [windowIsSmall, selectionPanel.current]);

  const getDescriptionWidth = () => {
    if (windowIsSmall) {
      setDescriptionWidth('100%');
    } else if (selectionPanel.current) {
      setDescriptionWidth(`${smallWindowThreshold - (selectionPanel.current.clientWidth || 0)}px`);
    }
  };

  const setSelected = (selection: ListOptionSelection | RadioOptionSelection[]) => {
    // Check if radio option to avoid type errors
    if (isRadioOptionSelection(selection)) setSelectedSuiteOptions(selection);
  };

  const createTestSession = (options: SuiteOption[] | null = null): void => {
    if (!test_suite_id) return;
    postTestSessions(test_suite_id, null, options)
      .then((testSession: TestSession | null) => {
        if (testSession && testSession.test_suite) {
          navigate(`/${testSession.test_suite_id}/${testSession.id}`);
          // Use window navigation as a workaround for router errors
          const root = basePath ? `/${basePath}` : window.location.origin;
          window.location.href = `${root}/${testSession.test_suite_id}/${testSession.id}`;
        }
      })
      .catch((e: Error) => {
        enqueueSnackbar(`Error while creating test session: ${e.message}`, { variant: 'error' });
      });
  };

  const renderTitle = () => {
    return (
      <Typography
        variant="h3"
        component="h1"
        align="center"
        sx={{
          color: lightTheme.palette.common.grayDarker,
          fontSize: windowIsSmall ? '2rem' : 'auto',
          fontWeight: 'bolder',
          letterSpacing: 2,
        }}
      >
        {testSuite?.title.toUpperCase()}
      </Typography>
    );
  };

  if (!showPage) {
    // 432px = 400 (default width of SelectionPanel Paper component) + 16px margin on each side
    return <Box ref={selectionPanel} width="432px" />;
  }

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
              minHeight: '400px',
              maxHeight: '100vh',
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
        px={windowIsSmall ? 0 : 8}
        my={3}
      >
        {/* Title */}
        <Box
          display="flex"
          alignItems="center"
          sx={windowIsSmall ? { mx: 2 } : { m: 4 }}
          maxWidth={descriptionWidth}
          maxHeight={windowIsSmall ? 'none' : '100%'}
        >
          {renderTitle()}
        </Box>
        {/* Description */}
        <Box
          display="flex"
          maxWidth={descriptionWidth}
          justifyContent="center"
          overflow="auto"
          px={2}
          mb={3}
        >
          <Typography
            variant="h6"
            component="h2"
            sx={{
              wordBreak: 'break-word',
            }}
          >
            <ReactMarkdown>
              {testSuite?.suite_summary || testSuite?.description || ''}
            </ReactMarkdown>
          </Typography>
        </Box>
      </Box>
      <Box
        display="flex"
        height={windowIsSmall ? 'none' : '100%'}
        width={windowIsSmall ? '100%' : 'none'}
        maxWidth={windowIsSmall ? '100%' : '50%'}
        justifyContent="center"
        alignItems="center"
        sx={{ backgroundColor: lightTheme.palette.common.grayLightest }}
      >
        <Box display="flex" ref={selectionPanel} justifyContent="center" maxHeight="100%" m={3}>
          <SelectionPanel
            title="Options"
            options={testSuite?.suite_options || []}
            setSelection={setSelected}
            showBackButton={true}
            backTooltipText="Back to Suites"
            submitAction={() => createTestSession(selectedSuiteOptions)}
            submitText="Start Testing"
          />
        </Box>
      </Box>
    </Container>
  );
};

export default SuiteOptionsPage;
