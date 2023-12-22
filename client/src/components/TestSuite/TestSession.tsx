import React, { FC, useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import { Box, Drawer, SwipeableDrawer, Toolbar } from '@mui/material';
import {
  TestInput,
  RunnableType,
  Runnable,
  TestRun,
  Result,
  TestSession,
  TestGroup,
  TestSuite,
  Request,
  TestOutput,
  ViewType,
  SuiteOptionChoice,
  isTestGroup,
  isTest,
} from '~/models/testSuiteModels';
import { deleteTestRun, getTestRunWithResults, postTestRun } from '~/api/TestRunsApi';
import { getCurrentTestSessionResults } from '~/api/TestSessionApi';
import ActionModal from '~/components/_common/ActionModal';
import InputsModal from '~/components/InputsModal/InputsModal';
import TestRunProgressBar from './TestRunProgressBar/TestRunProgressBar';
import TestSuiteTreeComponent from './TestSuiteTree/TestSuiteTree';
import TestSuiteDetailsPanel from './TestSuiteDetails/TestSuiteDetailsPanel';
import TestSuiteReport from './TestSuiteDetails/TestSuiteReport';
import ConfigMessagesDetailsPanel from './ConfigMessagesDetails/ConfigMessagesDetailsPanel';
import useStyles from './styles';
import { useSnackbar } from 'notistack';

import { useAppStore } from '~/store/app';
import { useTestSessionStore } from '~/store/testSession';
import { useEffectOnce } from '~/hooks/useEffectOnce';
import { useTimeout } from '~/hooks/useTimeout';
import { mapRunnableToId, resultsToMap, setIsRunning } from './TestSuiteUtilities';
import lightTheme from '~/styles/theme';

export interface TestSessionComponentProps {
  testSession: TestSession;
  previousResults: Result[];
  initialTestRun: TestRun | null;
  sessionData: Map<string, unknown>;
  suiteOptions?: SuiteOptionChoice[];
  drawerOpen: boolean;
  setSessionData: (data: Map<string, unknown>) => void;
  getSessionData?: (testSessionId: string) => void;
  toggleDrawer: (drawerOpen: boolean) => void;
}

const TestSessionComponent: FC<TestSessionComponentProps> = ({
  testSession,
  previousResults,
  initialTestRun,
  sessionData,
  suiteOptions,
  drawerOpen,
  setSessionData,
  getSessionData,
  toggleDrawer,
}) => {
  const { classes } = useStyles();
  const { enqueueSnackbar } = useSnackbar();
  const footerHeight = useAppStore((state) => state.footerHeight);
  const headerHeight = useAppStore((state) => state.headerHeight);
  const windowIsSmall = useAppStore((state) => state.windowIsSmall);
  const runnableId = useTestSessionStore((state) => state.runnableId);
  const testRunInProgress = useTestSessionStore((state) => state.testRunInProgress);
  const setRunnableId = useTestSessionStore((state) => state.setRunnableId);
  const setTestRunId = useTestSessionStore((state) => state.setTestRunId);
  const setTestRunInProgress = useTestSessionStore((state) => state.setTestRunInProgress);

  const [inputModalVisible, setInputModalVisible] = React.useState(false);
  const [waitingTestId, setWaitingTestId] = React.useState<string | null>();
  const [inputs, setInputs] = React.useState<TestInput[]>([]);
  const [runnableType, setRunnableType] = React.useState<RunnableType>(RunnableType.TestSuite);
  const [resultsMap, setResultsMap] = React.useState<Map<string, Result>>(
    resultsToMap(previousResults)
  );
  const [testRun, setTestRun] = React.useState<TestRun | null>(null);
  const [testRunCancelled, setTestRunCancelled] = React.useState<boolean>(false);
  const [showProgressBar, setShowProgressBar] = React.useState<boolean>(false);
  const [testSessionPolling, setTestSessionPolling] = React.useState(true);

  const poller = useTimeout();
  const runnableMap = React.useMemo(
    () => mapRunnableToId(testSession.test_suite),
    [testSession.test_suite]
  );
  const splitLocation = useLocation().hash.replace('#', '').split('/');
  let suiteName = splitLocation[0];
  const view = splitLocation[1] as ViewType;
  if (!runnableMap.get(suiteName)) {
    Array.from(runnableMap).forEach(([key, value]) => {
      if (isTestGroup(value) && value.short_id === suiteName) {
        suiteName = key;
      } else if (isTest(value) && value.short_id === suiteName) {
        suiteName = key.substring(0, key.lastIndexOf('-'));
      }
    });
  }
  const selectedRunnable = runnableMap.get(suiteName) ? suiteName : testSession.test_suite.id;

  resultsMap.forEach((result, runnableId) => {
    const runnable = runnableMap.get(runnableId);
    if (runnable) {
      runnable.result = result;
    }
  });

  useEffect(() => {
    if (!testRun && initialTestRun) {
      setTestRun(initialTestRun);
      if (testRunIsInProgress(initialTestRun)) {
        setShowProgressBar(true);
        pollTestRunResults(initialTestRun);
      }
    }

    if (testRunIsInProgress(testRun)) {
      const runnable = runnableMap.get(runnableId);
      if (runnable) setIsRunning(runnable, true);
    }
  });

  // Set testRunIsInProgress and is_running status when testRun changes
  useEffect(() => {
    const inProgress = testRunIsInProgress(testRun);
    setTestRunInProgress(inProgress);

    // Wipe both currently running runnable and selected (currently rendered) runnable
    if (!inProgress) {
      const runnableFromSelected = runnableMap.get(selectedRunnable);
      if (runnableFromSelected) setIsRunning(runnableFromSelected, false);

      const runnableFromId = runnableMap.get(runnableId);
      if (runnableFromId) setIsRunning(runnableFromId, false);
    }
  }, [testRun]);

  useEffect(() => {
    testSession.test_suite.inputs?.forEach((input: TestInput) => {
      const defaultValue = input.default || '';
      sessionData.set(input.name, sessionData.get(input.name) || defaultValue);
    });
    setSessionData(new Map(sessionData));
  }, [testSession]);

  useEffect(() => {
    let waitingId = null;
    if (testRun?.status === 'waiting') {
      resultsMap.forEach((result) => {
        if (result.test_id && result.result === 'wait') {
          waitingId = result.test_id;
        }
      });
    }
    setWaitingTestId(waitingId);
  }, [resultsMap]);

  // when leaving the TestSession, we want to cancel the poller
  useEffectOnce(() => {
    return () => {
      setTestSessionPolling(false);
    };
  });

  const showInputsModal = (runnableType: RunnableType, runnableId: string, inputs: TestInput[]) => {
    setInputs(inputs);
    setRunnableType(runnableType);
    setRunnableId(runnableId);
    setInputModalVisible(true);
  };

  const latestResult = (results: Result[] | null | undefined): Result | null => {
    if (!results) {
      return null;
    }
    return results.reduce((lastResult, result) => {
      return Date.parse(result.updated_at) > Date.parse(lastResult.updated_at)
        ? result
        : lastResult;
    }, results[0]);
  };

  const pollTestRunResults = (testRun: TestRun): void => {
    getTestRunWithResults(testRun.id, latestResult(testRun.results)?.updated_at)
      .then((testRunResults: TestRun | null) => {
        setTestRun(testRunResults);
        if (testRunResults?.results) {
          testRunResults.results.forEach((result: Result) => {
            const outputs: TestOutput[] = result.outputs;
            outputs.forEach((output: TestOutput) => {
              if (output.value) {
                sessionData.set(output.name, output.value);
              }
            });
          });
          setSessionData(new Map(sessionData));

          let updatedMap = resultsToMap(testRunResults.results, resultsMap);
          // If wait test is causing race condition rendering bugs, fetch full results again
          if (
            testRunResults?.status === 'done' &&
            Array.from(updatedMap.values()).some((value) => value.result === 'wait')
          ) {
            getCurrentTestSessionResults(testSession.id)
              .then((results) => {
                if (results) {
                  updatedMap = resultsToMap(results, resultsMap);
                  setResultsMap(updatedMap);
                } else {
                  enqueueSnackbar('Failed to load results', { variant: 'error' });
                }
              })
              .catch((e: Error) => {
                enqueueSnackbar(`Error while getting test results: ${e.message}`, {
                  variant: 'error',
                });
              });
          } else {
            setResultsMap(updatedMap);
          }
        }
        if (testRunResults && testRunIsInProgress(testRunResults) && testSessionPolling) {
          poller.current = setTimeout(() => pollTestRunResults(testRunResults), 500);
        }
      })
      .catch((e: Error) => {
        enqueueSnackbar(`Error while getting test run: ${e.message}`, {
          variant: 'error',
        });
      });
  };

  const updateRequest = (requestId: string, resultId: string, request: Request): void => {
    const result = Array.from(resultsMap.values()).find((result) => result.id === resultId);
    if (result && result.requests) {
      const requestIndex = result.requests.findIndex((request) => request.id === requestId);
      result.requests[requestIndex] = request;
      setResultsMap(new Map(resultsMap));
    }
  };

  const runTests = (runnableType: RunnableType, runnableId: string) => {
    const runnable = runnableMap.get(runnableId);
    runnable?.inputs?.forEach((input: TestInput) => {
      input.value = sessionData.get(input.name);
    });
    if (runnable?.inputs && runnable.inputs.length > 0) {
      showInputsModal(runnableType, runnableId, runnable.inputs);
    } else {
      createTestRun(runnableType, runnableId, []);
    }
  };

  const createTestRun = (runnableType: RunnableType, runnableId: string, inputs: TestInput[]) => {
    inputs.forEach((input: TestInput) => {
      sessionData.set(input.name, input.value as string);
    });
    setSessionData(new Map(sessionData));
    postTestRun(testSession.id, runnableType, runnableId, inputs)
      .then((testRun: TestRun | null) => {
        if (testRun) {
          const runnable = runnableMap.get(runnableId);
          if (runnable) setIsRunning(runnable, true);
          setTestRun(testRun);
          setTestRunId(testRun.id);
          setTestRunCancelled(false);
          setShowProgressBar(true);
          pollTestRunResults(testRun);
        }
      })
      .catch((e: Error) => {
        enqueueSnackbar(`Error while running test(s): ${e.message}`, { variant: 'error' });
      });
  };

  const cancelTestRun = () => {
    if (testRun) {
      deleteTestRun(testRun.id)
        .then(() => setTestRunCancelled(true))
        .catch((e: Error) =>
          enqueueSnackbar(`Error while cancelling test run: ${e.message}`, {
            variant: 'error',
          })
        );
    }
  };

  const testRunIsInProgress = (testRun: TestRun | null): boolean =>
    testRun?.status
      ? ['running', 'queued', 'waiting', 'cancelling'].includes(testRun?.status)
      : false;

  const renderTestRunProgressBar = () => {
    const duration = testRunInProgress ? null : 2000;
    return (
      <TestRunProgressBar
        showProgressBar={showProgressBar}
        setShowProgressBar={setShowProgressBar}
        cancelled={testRunCancelled}
        cancelTestRun={cancelTestRun}
        duration={duration}
        testRun={testRun}
        resultsMap={resultsMap}
      />
    );
  };

  const renderDrawerContents = () => {
    return (
      <nav className={classes.drawer}>
        <TestSuiteTreeComponent
          testSuite={testSession.test_suite}
          selectedRunnable={selectedRunnable}
          view={view || 'run'}
          presets={testSession.test_suite.presets}
          getSessionData={getSessionData}
          testSessionId={testSession.id}
        />
      </nav>
    );
  };

  const renderView = (view: ViewType) => {
    const runnable = runnableMap.get(selectedRunnable);
    if (!runnable) return null;
    switch (view) {
      case 'report':
        // This is a little strange because we are only allowing reports
        // at the suite level right now for simplicity.
        return (
          <TestSuiteReport
            testSuite={runnable as TestSuite}
            suiteOptions={suiteOptions}
            updateRequest={updateRequest}
          />
        );
      case 'config':
        // Config messages are only defined at the suite level.
        return <ConfigMessagesDetailsPanel testSuite={runnable as TestSuite} />;
      default:
        return (
          <TestSuiteDetailsPanel
            runnable={runnable as TestSuite | TestGroup}
            runTests={runTests}
            updateRequest={updateRequest}
            testSuiteId={testSession.test_suite.id}
            configMessages={testSession.test_suite.configuration_messages}
          />
        );
    }
  };

  return (
    <Box className={classes.testSuiteMain}>
      {renderTestRunProgressBar()}
      {windowIsSmall ? (
        <SwipeableDrawer
          anchor="left"
          open={drawerOpen}
          onClose={() => toggleDrawer(false)}
          onOpen={() => toggleDrawer(true)}
          swipeAreaWidth={56}
          disableSwipeToOpen={false}
          ModalProps={{
            keepMounted: true,
            BackdropProps: { classes: { root: classes.swipeableDrawerHeight } },
          }}
          PaperProps={{ elevation: 0 }}
          classes={{ paper: classes.swipeableDrawerHeight }}
        >
          {/* Spacer to be updated with header height */}
          <Toolbar sx={{ minHeight: `${headerHeight}px !important` }} />
          {renderDrawerContents()}
          {/* Spacer to be updated with footer height */}
          <Toolbar sx={{ minHeight: `${footerHeight}px !important` }} />
        </SwipeableDrawer>
      ) : (
        <Drawer
          variant="permanent"
          anchor="left"
          className={classes.hidePrint}
          classes={{ paper: classes.drawerPaper }}
        >
          {renderDrawerContents()}
        </Drawer>
      )}
      <main
        style={{
          overflow: 'auto',
          width: '100%',
          backgroundColor: lightTheme.palette.common.grayLightest,
        }}
      >
        <Box className={classes.contentContainer} p={windowIsSmall ? 1 : 4}>
          {renderView(view || 'run')}
          {inputModalVisible && (
            <InputsModal
              createTestRun={createTestRun}
              runnableType={runnableType}
              runnableId={runnableId}
              title={(runnableMap.get(selectedRunnable) as Runnable).title}
              inputInstructions={(runnableMap.get(selectedRunnable) as Runnable).input_instructions}
              inputs={inputs}
              sessionData={sessionData}
              hideModal={() => setInputModalVisible(false)}
            />
          )}
          <ActionModal
            cancelTestRun={cancelTestRun}
            message={waitingTestId ? resultsMap.get(waitingTestId)?.result_message : ''}
            modalVisible={!!waitingTestId}
          />
        </Box>
      </main>
    </Box>
  );
};

export default TestSessionComponent;
