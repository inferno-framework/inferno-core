import React, { FC, Fragment } from 'react';
import { Button, Tooltip, IconButton } from '@mui/material';
import PlayArrowIcon from '@mui/icons-material/PlayArrow';
import PlayCircleIcon from '@mui/icons-material/PlayCircle';
import {
  TestGroup,
  RunnableType,
  TestSuite,
  Test,
  runnableIsTestSuite,
} from 'models/testSuiteModels';

export interface TestRunButtonProps {
  runnable: TestSuite | TestGroup | Test;
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
  const showRunButton = runnableIsTestSuite(runnable) || (runnable as TestGroup).user_runnable;
  const runButton = showRunButton ? (
    <Tooltip title={testRunInProgress ? 'Disabled - Ongoing Test.' : ''} arrow>
      {buttonText ? (
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
          <PlayCircleIcon />
        </IconButton>
      )}
    </Tooltip>
  ) : (
    <Fragment />
  );

  return runButton;
};

export default TestRunButton;
