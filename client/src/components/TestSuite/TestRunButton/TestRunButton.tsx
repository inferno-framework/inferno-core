import React, { FC } from 'react';
import { Button, Tooltip, IconButton } from '@mui/material';
import PlayArrowIcon from '@mui/icons-material/PlayArrow';
import PlayCircleIcon from '@mui/icons-material/PlayCircle';
import { TestGroup, RunnableType, TestSuite, Test } from 'models/testSuiteModels';

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
  /* Need to explicitly check against false because undefined needs to be treated
   * as true. */
  const showRunButton = (runnable as TestGroup).user_runnable !== false;

  return (
    <>
      {showRunButton && (
        <Tooltip title={testRunInProgress ? 'Disabled - Ongoing Test' : 'Run Test'} arrow>
          {/* Necessary to enable tooltip on disabled button */}
          <span>
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
          </span>
        </Tooltip>
      )}
    </>
  );
};

export default TestRunButton;
