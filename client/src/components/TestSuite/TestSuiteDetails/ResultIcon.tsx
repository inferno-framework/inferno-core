import React, { FC } from 'react';
import { Result } from '~/models/testSuiteModels';
import { Tooltip } from '@mui/material';
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

export interface ResultIconProps {
  result?: Result;
  isRunning?: boolean;
}

const ResultIcon: FC<ResultIconProps> = ({ result, isRunning }) => {
  // console.log(isRunning);

  if (isRunning) {
    return (
      <Tooltip title="pending">
        <Pending style={{ color: grey[500] }} /* data-testid={`${result.id}-${result.result}`} */ />
      </Tooltip>
    );
  } else if (result) {
    switch (result.result) {
      case 'pass':
        return (
          <Tooltip title="passed">
            <CheckCircle
              style={{ color: result.optional ? green[100] : green[500] }}
              data-testid={`${result.id}-${result.result}`}
            />
          </Tooltip>
        );
      case 'fail':
        return (
          <Tooltip title="failed">
            <Cancel
              style={{ color: result.optional ? grey[500] : red[500] }}
              data-testid={`${result.id}-${result.result}`}
            />
          </Tooltip>
        );
      case 'cancel':
        return (
          <Tooltip title="cancel">
            <Cancel
              style={{ color: result.optional ? grey[500] : red[500] }}
              data-testid={`${result.id}-${result.result}`}
            />
          </Tooltip>
        );
      case 'skip':
        return (
          <Tooltip title="skipped">
            <Block
              style={{ color: result.optional ? grey[500] : orange[800] }}
              data-testid={`${result.id}-${result.result}`}
            />
          </Tooltip>
        );
      case 'omit':
        return (
          <Tooltip title="omitted">
            <Circle style={{ color: grey[500] }} data-testid={`${result.id}-${result.result}`} />
          </Tooltip>
        );
      case 'error':
        return (
          <Tooltip title="error">
            <Error
              style={{ color: result.optional ? grey[500] : purple[500] }}
              data-testid={`${result.id}-${result.result}`}
            />
          </Tooltip>
        );
      case 'wait':
        return (
          <Tooltip title="wait">
            <AccessTime data-testid={`${result.id}-${result.result}`} />
          </Tooltip>
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
