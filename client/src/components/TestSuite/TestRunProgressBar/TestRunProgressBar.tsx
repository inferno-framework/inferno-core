import React, { FC } from 'react';
import { TestRun, Result } from '~/models/testSuiteModels';
import {
  Box,
  IconButton,
  CircularProgress,
  LinearProgress,
  Snackbar,
  Typography,
} from '@mui/material';
import AccessTimeIcon from '@mui/icons-material/AccessTime';
import CancelIcon from '@mui/icons-material/Cancel';
import DoneIcon from '@mui/icons-material/Done';
import FilterNoneIcon from '@mui/icons-material/FilterNone';
import CustomTooltip from '~/components/_common/CustomTooltip';
import lightTheme from '~/styles/theme';
import { useAppStore } from '~/store/app';
import useStyles from './styles';

export interface TestRunProgressBarProps {
  showProgressBar: boolean;
  setShowProgressBar: (show: boolean) => void;
  cancelled: boolean;
  cancelTestRun: () => void;
  duration: number | null;
  testRun: TestRun | null;
  resultsMap: Map<string, Result>;
}

const StatusIndicator = (status: string | null | undefined) => {
  switch (status) {
    case 'running':
      return (
        <CustomTooltip title="Running">
          <CircularProgress size={24} />
        </CustomTooltip>
      );
    case 'cancelling':
      return (
        <CustomTooltip title="Cancelling">
          <CircularProgress size={24} />
        </CustomTooltip>
      );
    case 'waiting':
      return (
        <CustomTooltip title="Waiting">
          <AccessTimeIcon color="primary" />
        </CustomTooltip>
      );
    case 'queued':
      return (
        <CustomTooltip title="Queued">
          <FilterNoneIcon color="primary" />
        </CustomTooltip>
      );
    case 'done':
      return (
        <CustomTooltip title="Done">
          <DoneIcon color="primary" />
        </CustomTooltip>
      );
    default:
      return null;
  }
};

const completedTestCount = (resultsMap: Map<string, Result>, testRun: TestRun | null) => {
  let count = 0;
  resultsMap.forEach((result) => {
    if (result.test_id && result.test_run_id === testRun?.id) {
      count++;
    }
  });
  return count;
};

const TestRunProgressBar: FC<TestRunProgressBarProps> = ({
  showProgressBar,
  setShowProgressBar,
  cancelled,
  cancelTestRun,
  duration,
  testRun,
  resultsMap,
}) => {
  const { classes } = useStyles();
  const footerHeight = useAppStore((state) => state.footerHeight);
  const cancellable = testRun?.status !== 'cancelling' && testRun?.status !== 'done';
  const statusIndicator = StatusIndicator(testRun?.status);
  const testCount = testRun?.test_count || 0;
  const completedCount = completedTestCount(resultsMap, testRun);

  return (
    <Snackbar
      open={showProgressBar}
      anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
      autoHideDuration={duration}
      onClose={() => {
        if (completedCount === testCount || testRun?.status === 'done' || cancelled) {
          setShowProgressBar(false);
        }
      }}
      ClickAwayListenerProps={{ mouseEvent: false }}
      style={{
        marginBottom: `${footerHeight}px`,
        zIndex: lightTheme.zIndex.snackbar,
      }}
      data-testid="progress-bar"
    >
      <Box
        display="flex"
        alignItems="center"
        bgcolor="text.secondary"
        p="0.5em"
        borderRadius="0.5em"
        role="aside"
      >
        <Box margin="2px 0 0 4px">{statusIndicator}</Box>
        <Box minWidth={200} mx={1} color="background.paper">
          {testRun?.status === 'cancelling' ? (
            <Typography variant="body1">Cancelling Test Run...</Typography>
          ) : (
            <LinearProgress
              variant="determinate"
              value={testRun?.status === 'done' ? 100 : (100 * completedCount) / testCount || 0}
              className={classes.linearProgress}
            />
          )}
        </Box>
        <Box color="background.paper">
          <Typography variant="body1">
            {testRun?.status === 'done' ? testCount : completedCount}/{testCount}
          </Typography>
        </Box>
        <CustomTooltip title="Cancel Test Run">
          <IconButton
            aria-label="cancel"
            disabled={!cancellable}
            color="primary"
            onClick={cancelTestRun}
            className={classes.cancelButton}
          >
            <CancelIcon />
          </IconButton>
        </CustomTooltip>
      </Box>
    </Snackbar>
  );
};

export default TestRunProgressBar;
