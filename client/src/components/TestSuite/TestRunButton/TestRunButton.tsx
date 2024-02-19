import React, { FC } from 'react';
import { Button } from '@mui/material';
import PlayArrowIcon from '@mui/icons-material/PlayArrow';
import PlayCircleIcon from '@mui/icons-material/PlayCircle';
import { TestGroup, Runnable, RunnableType } from '~/models/testSuiteModels';
import CustomTooltip from '~/components/_common/CustomTooltip';
import lightTheme from '~/styles/theme';

import { useTestSessionStore } from '~/store/testSession';

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
  const testRunInProgress = useTestSessionStore((state) => state.testRunInProgress);
  /* Need to explicitly check against false because undefined needs to be treated
   * as true. */
  const showRunButton = (runnable as TestGroup).user_runnable !== false;

  const textButton = (
    <Button
      variant="contained"
      disabled={testRunInProgress}
      color="secondary"
      size="small"
      disableElevation
      onClick={() => {
        runTests(runnableType, runnable.id);
      }}
      startIcon={<PlayArrowIcon />}
      data-testid={`runButton-${runnable.id}`}
    >
      {buttonText}
    </Button>
  );

  // Custom icon button to resolve nested interactive control error
  const iconButton = (
    <CustomTooltip describeChild title={`Run ${runnable.title}`}>
      <PlayCircleIcon
        aria-label={`Run ${runnable.title}${
          testRunInProgress ? ' Disabled - Test Run in Progress' : ''
        }`}
        aria-hidden={false}
        tabIndex={0}
        color={testRunInProgress ? 'disabled' : 'secondary'}
        data-testid={`runButton-${runnable.id}`}
        onClick={() => {
          if (!testRunInProgress) runTests(runnableType, runnable.id);
        }}
        onKeyDown={(e) => {
          e.stopPropagation();
          if (e.key === 'Enter' && !testRunInProgress) {
            runTests(runnableType, runnable.id);
          }
        }}
        sx={{
          margin: '0 8px',
          padding: '0.25em 0.25em',
          ':hover': testRunInProgress
            ? {}
            : {
                background: lightTheme.palette.common.grayLightest,
                borderRadius: '50%',
              },
        }}
      />
    </CustomTooltip>
  );

  if (!showRunButton) {
    return <></>;
  } else if (!buttonText) {
    return iconButton;
  } else {
    return textButton;
  }
};

export default TestRunButton;
