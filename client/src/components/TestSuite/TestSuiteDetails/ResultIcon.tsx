import React, { FC } from 'react';
import { Result } from '~/models/testSuiteModels';
import { red, orange, green, purple, grey } from '@mui/material/colors';
import {
  AccessTime,
  Block,
  Cancel,
  CheckCircle,
  Circle,
  Error,
  Pending,
  RadioButtonUnchecked,
} from '@mui/icons-material';
import CustomTooltip from '~/components/_common/CustomTooltip';
import { useTestSessionStore } from '~/store/testSession';

export interface ResultIconProps {
  result?: Result;
  isRunning?: boolean;
}

const ResultIcon: FC<ResultIconProps> = ({ result, isRunning }) => {
  const testRunId = useTestSessionStore((state) => state.testRunId);

  // Pending is true if the runnable is in the current test
  // run and result is not for other test runs
  if (isRunning && result?.test_run_id !== testRunId) {
    return (
      <CustomTooltip title="pending">
        <Pending
          tabIndex={0}
          aria-hidden="false"
          style={{ color: grey[500] }} /* data-testid={`${result.id}-${result.result}`} */
        />
      </CustomTooltip>
    );
  }

  switch (result?.result) {
    case 'pass':
      return (
        <CustomTooltip title="passed">
          <CheckCircle
            tabIndex={0}
            aria-hidden="false"
            style={{ color: result.optional ? green[100] : green[500] }}
            data-testid={`${result.id}-${result.result}`}
          />
        </CustomTooltip>
      );
    case 'fail':
      return (
        <CustomTooltip title="failed">
          <Cancel
            tabIndex={0}
            aria-hidden="false"
            style={{ color: result.optional ? red[100] : red[700] }}
            data-testid={`${result.id}-${result.result}`}
          />
        </CustomTooltip>
      );
    case 'cancel':
      return (
        <CustomTooltip title="cancel">
          <Cancel
            tabIndex={0}
            aria-hidden="false"
            style={{ color: result.optional ? red[100] : red[700] }}
            data-testid={`${result.id}-${result.result}`}
          />
        </CustomTooltip>
      );
    case 'skip':
      return (
        <CustomTooltip title="skipped">
          <Block
            tabIndex={0}
            aria-hidden="false"
            style={{ color: result.optional ? orange[200] : orange[800] }}
            data-testid={`${result.id}-${result.result}`}
          />
        </CustomTooltip>
      );
    case 'omit':
      return (
        <CustomTooltip title="omitted">
          <Circle
            tabIndex={0}
            aria-hidden="false"
            style={{ color: result.optional ? grey[300] : grey[600] }}
            data-testid={`${result.id}-${result.result}`}
          />
        </CustomTooltip>
      );
    case 'error':
      return (
        <CustomTooltip title="error">
          <Error
            tabIndex={0}
            aria-hidden="false"
            style={{ color: result.optional ? purple[100] : purple[500] }}
            data-testid={`${result.id}-${result.result}`}
          />
        </CustomTooltip>
      );
    case 'wait':
      return (
        <CustomTooltip title="wait">
          <AccessTime
            tabIndex={0}
            aria-hidden="false"
            data-testid={`${result.id}-${result.result}`}
          />
        </CustomTooltip>
      );

    default:
      return (
        <CustomTooltip title="no result">
          <RadioButtonUnchecked
            tabIndex={0}
            aria-hidden="false"
            style={{
              color: grey[500],
            }}
          />
        </CustomTooltip>
      );
  }
};

export default ResultIcon;
