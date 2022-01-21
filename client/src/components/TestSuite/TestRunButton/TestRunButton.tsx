import React, { FC, Fragment } from 'react';
import { Tooltip, IconButton } from '@mui/material';
import PlayArrowIcon from '@mui/icons-material/PlayArrow';
import {
  TestGroup,
  RunnableType,
  TestSuite,
  Test,
  runnableIsTestSuite,
} from 'models/testSuiteModels';

export interface TestRunButtonProps {
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  setIsRunning: (isRunning: boolean) => void;
  runnable: TestSuite | TestGroup | Test;
  testRunInProgress: boolean;
}

const TestRunButton: FC<TestRunButtonProps> = ({
  runTests,
  setIsRunning,
  runnable,
  testRunInProgress,
}) => {
  const runnableType = 'tests' in runnable ? RunnableType.TestGroup : RunnableType.TestSuite;
  const showRunButton = runnableIsTestSuite(runnable) || (runnable as TestGroup).user_runnable;
  const runButton = showRunButton ? (
    <Tooltip title={testRunInProgress ? 'Disabled - Ongoing Test.' : ''} arrow>
      <div>
        <IconButton
          disabled={testRunInProgress}
          color="secondary"
          edge="end"
          size="small"
          onClick={() => {
            setIsRunning(true);
            runTests(runnableType, runnable.id);
          }}
          data-testid={`runButton-${runnable.id}`}
        >
          <PlayArrowIcon />
        </IconButton>
      </div>
    </Tooltip>
  ) : (
    <Fragment />
  );

  return runButton;
};

export default TestRunButton;
