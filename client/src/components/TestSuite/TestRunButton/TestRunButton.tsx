import React, { FC } from 'react';
import { Button, IconButton } from '@mui/material';
import PlayArrowIcon from '@mui/icons-material/PlayArrow';
import PlayCircleIcon from '@mui/icons-material/PlayCircle';
import { TestGroup, Runnable, RunnableType } from 'models/testSuiteModels';

export interface TestRunButtonProps {
  runnable: Runnable;
  runnableType: RunnableType;
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  testRunInProgress: boolean;
  buttonText?: string;
}

const TestRunButton: FC<TestRunButtonProps> = ({
  runTests,
  runnable,
  runnableType,
  testRunInProgress,
  buttonText,
}) => {
  /* Need to explicitly check against false because undefined needs to be treated
   * as true. */
  const showRunButton = (runnable as TestGroup).user_runnable !== false;

  return (
    <>
      {showRunButton &&
        (buttonText ? (
          <Button
            variant="contained"
            disabled={testRunInProgress}
            color="secondary"
            size="small"
            disableElevation
            onClick={() => {
              runTests(runnableType, runnable.id);
            }}
            endIcon={<PlayArrowIcon />}
            data-testid={`runButton-${runnable.id}`}
          >
            {buttonText}
          </Button>
        ) : (
          <IconButton
            title="Run Test"
            disabled={testRunInProgress}
            color="secondary"
            edge="end"
            size="small"
            onClick={() => {
              runTests(runnableType, runnable.id);
            }}
            data-testid={`runButton-${runnable.id}`}
            sx={{ margin: '0 4px' }}
          >
            <PlayCircleIcon aria-label="run test" />
          </IconButton>
        ))}
    </>
  );
};

export default TestRunButton;
