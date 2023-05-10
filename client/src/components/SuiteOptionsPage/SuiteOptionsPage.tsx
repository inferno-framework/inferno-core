import React, { FC, useEffect, useRef } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { Typography, Box } from '@mui/material';
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

export interface SuiteOptionsPageProps {
  testSuite?: TestSuite;
}

const SuiteOptionsPage: FC<SuiteOptionsPageProps> = ({ testSuite }) => {
  const navigate = useNavigate();
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
  const selectionPanel = useRef<HTMLElement>(null);

  useEffect(() => {
    if (
      // If no suite or no options and no description, then start a test session
      !testSuite?.suite_summary &&
      (!testSuite?.suite_options || testSuite?.suite_options.length === 0)
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
          color: lightTheme.palette.common.grayDarkest,
          fontSize: windowIsSmall ? '2rem' : 'auto',
          fontWeight: 'bolder',
          letterSpacing: 2,
        }}
      >
        {testSuite?.title.toUpperCase()}
      </Typography>
    );
  };

  return (
    <Box
      display="flex"
      alignItems="center"
      justifyContent="center"
      flexDirection={windowIsSmall ? 'column' : 'row'}
      minHeight="600px"
      height="100%"
      // maxHeight="100vh"
      role="main"
    >
      {/* Title */}
      {windowIsSmall && (
        <Box display="flex" alignItems="center" maxWidth="800px" sx={{ m: 2 }}>
          {renderTitle()}
        </Box>
      )}
      <Box
        display="flex"
        flexWrap="wrap"
        alignItems="center"
        justifyContent="space-evenly"
        width="100%"
        sx={windowIsSmall ? { overflow: 'auto' } : { mt: 4, pb: 8, overflow: 'hidden' }}
      >
        {/* Title */}
        {!windowIsSmall && (
          <Box
            display="flex"
            maxWidth={descriptionWidth}
            maxHeight={windowIsSmall ? 'none' : '100%'}
            overflow="auto"
            mt={3}
          >
            <Box alignItems="center" maxWidth="800px" sx={{ m: 4 }}>
              {renderTitle()}
            </Box>
          </Box>
        )}
        {/* Description */}
        <Box
          maxWidth={descriptionWidth}
          maxHeight={windowIsSmall ? 'none' : '100%'}
          overflow="auto"
          mb={3}
        >
          <Typography
            variant="h6"
            component="h2"
            pr={4}
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
      </Box>
      <Box
        display="flex"
        height="100%"
        width="100%"
        justifyContent="center"
        alignItems="center"
        sx={{ backgroundColor: lightTheme.palette.common.gray }}
      >
        <Box ref={selectionPanel} justifyContent="center" maxHeight="100%" overflow="auto" p={3}>
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
    </Box>
  );
};

export default SuiteOptionsPage;
