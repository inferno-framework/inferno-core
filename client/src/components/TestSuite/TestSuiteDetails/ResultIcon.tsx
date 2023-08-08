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
        <Pending style={{ color: grey[500] }} /* data-testid={`${result.id}-${result.result}`} */ />
      </CustomTooltip>
    );
  } else if (result) {
    switch (result.result) {
      case 'pass':
        return (
          <CustomTooltip title="passed">
            <CheckCircle
              style={{ color: result.optional ? green[100] : green[500] }}
              data-testid={`${result.id}-${result.result}`}
            />
          </CustomTooltip>
        );
      case 'fail':
        return (
          <CustomTooltip title="failed">
            <Cancel
              style={{ color: result.optional ? grey[500] : red[500] }}
              data-testid={`${result.id}-${result.result}`}
            />
          </CustomTooltip>
        );
      case 'cancel':
        return (
          <CustomTooltip title="cancel">
            <Cancel
              style={{ color: result.optional ? grey[500] : red[500] }}
              data-testid={`${result.id}-${result.result}`}
            />
          </CustomTooltip>
        );
      case 'skip':
        return (
          <CustomTooltip title="skipped">
            <Block
              style={{ color: result.optional ? grey[500] : orange[800] }}
              data-testid={`${result.id}-${result.result}`}
            />
          </CustomTooltip>
        );
      case 'omit':
        return (
          <CustomTooltip title="omitted">
            <Circle style={{ color: grey[500] }} data-testid={`${result.id}-${result.result}`} />
          </CustomTooltip>
        );
      case 'error':
        return (
          <CustomTooltip title="error">
            <Error
              style={{ color: result.optional ? grey[500] : purple[500] }}
              data-testid={`${result.id}-${result.result}`}
            />
          </CustomTooltip>
        );
      case 'wait':
        return (
          <CustomTooltip title="wait">
            <AccessTime data-testid={`${result.id}-${result.result}`} />
          </CustomTooltip>
        );

      default:
        return (
          <RadioButtonUnchecked
            style={{
              color: grey[500],
            }}
          />
        );
    }
  } else {
    return (
      <RadioButtonUnchecked
        style={{
          color: grey[500],
        }}
      />
    );
  }
};

export default ResultIcon;
