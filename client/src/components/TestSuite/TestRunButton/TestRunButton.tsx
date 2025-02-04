import React, { FC } from 'react';
import { useLocation } from 'react-router-dom';
import { Button } from '@mui/material';
import { PlayArrow, PlayCircle, Visibility } from '@mui/icons-material';
import { TestGroup, Runnable, RunnableType } from '~/models/testSuiteModels';
import { useTestSessionStore } from '~/store/testSession';
import CustomTooltip from '~/components/_common/CustomTooltip';
import { testRunInProgress } from '~/components/TestSuite/TestSuiteUtilities';
import lightTheme from '~/styles/theme';

export interface TestRunButtonProps {
  runnable: Runnable;
  runnableType: RunnableType;
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  buttonText?: string;
}

const TestRunButton: FC<TestRunButtonProps> = ({
  runTests,
  runnable,
  runnableType,
  buttonText,
}) => {
  const currentRunnables = useTestSessionStore((state) => state.currentRunnables);
  const viewOnly = useTestSessionStore((state) => state.viewOnly);
  const showRunButton = (runnable as TestGroup).user_runnable !== false;
  const inProgress = testRunInProgress(currentRunnables, useLocation().pathname);

  const textButton = (
    <Button
      variant="contained"
      disabled={inProgress}
      color="secondary"
      size="small"
      disableElevation
      onClick={() => {
        runTests(runnableType, runnable.id);
      }}
      startIcon={viewOnly ? <Visibility /> : <PlayArrow />}
      data-testid={`runButton-${runnable.id}`}
    >
      {buttonText}
    </Button>
  );

  // Custom icon buttons to resolve nested interactive control error
  const runIconButton = (
    <CustomTooltip describeChild title={`Run ${runnable.title}`}>
      <PlayCircle
        aria-label={`Run ${runnable.title}${inProgress ? ' Disabled - Test Run in Progress' : ''}`}
        aria-hidden={false}
        tabIndex={0}
        color={inProgress ? 'disabled' : 'secondary'}
        data-testid={`runButton-${runnable.id}`}
        onClick={() => {
          if (!inProgress) runTests(runnableType, runnable.id);
        }}
        onKeyDown={(e) => {
          e.stopPropagation();
          if (e.key === 'Enter' && !inProgress) {
            runTests(runnableType, runnable.id);
          }
        }}
        sx={{
          margin: '0 8px',
          padding: '0.25em 0.25em',
          ':hover': inProgress
            ? {}
            : {
                background: lightTheme.palette.common.grayLight,
                borderRadius: '50%',
              },
        }}
      />
    </CustomTooltip>
  );

  const viewIconButton = (
    <CustomTooltip describeChild title={`View ${runnable.title} Inputs`}>
      <Visibility
        aria-label={`View ${runnable.title}${inProgress ? ' Disabled - Test Run in Progress' : ''}`}
        aria-hidden={false}
        tabIndex={0}
        color={inProgress ? 'disabled' : 'secondary'}
        data-testid={`runButton-${runnable.id}`}
        onClick={() => {
          if (!inProgress) runTests(runnableType, runnable.id);
        }}
        onKeyDown={(e) => {
          e.stopPropagation();
          if (e.key === 'Enter' && !inProgress) {
            runTests(runnableType, runnable.id);
          }
        }}
        sx={{
          margin: '0 8px',
          padding: '0.25em 0.25em',
          ':hover': inProgress
            ? {}
            : {
                background: lightTheme.palette.common.grayLight,
                borderRadius: '50%',
              },
        }}
      />
    </CustomTooltip>
  );

  if (!showRunButton) {
    return <></>;
  } else if (!buttonText) {
    return viewOnly ? viewIconButton : runIconButton;
  } else {
    return textButton;
  }
};

export default TestRunButton;
