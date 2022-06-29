import React, { FC } from 'react';
import { Result } from '~/models/testSuiteModels';
import { Tooltip } from '@mui/material';
import { red, orange, green, purple, grey } from '@mui/material/colors';
import AccessTimeIcon from '@mui/icons-material/AccessTime';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import CancelIcon from '@mui/icons-material/Cancel';
import ErrorIcon from '@mui/icons-material/Error';
import CircleIcon from '@mui/icons-material/Circle';
import BlockIcon from '@mui/icons-material/Block';
import RadioButtonUncheckedIcon from '@mui/icons-material/RadioButtonUnchecked';

export interface ResultIconProps {
  result?: Result;
}

const ResultIcon: FC<ResultIconProps> = ({ result }) => {
  if (result) {
    switch (result.result) {
      case 'pass':
        return (
          <Tooltip title="passed">
            <CheckCircleIcon
              style={{ color: result.optional ? green[100] : green[500] }}
              data-testid={`${result.id}-${result.result}`}
            />
          </Tooltip>
        );
      case 'fail':
        return (
          <Tooltip title="failed">
            <CancelIcon
              style={{ color: result.optional ? grey[500] : red[500] }}
              data-testid={`${result.id}-${result.result}`}
            />
          </Tooltip>
        );
      case 'cancel':
        return (
          <Tooltip title="cancel">
            <CancelIcon
              style={{ color: result.optional ? grey[500] : red[500] }}
              data-testid={`${result.id}-${result.result}`}
            />
          </Tooltip>
        );
      case 'skip':
        return (
          <Tooltip title="skipped">
            <BlockIcon
              style={{ color: result.optional ? grey[500] : orange[800] }}
              data-testid={`${result.id}-${result.result}`}
            />
          </Tooltip>
        );
      case 'omit':
        return (
          <Tooltip title="omitted">
            <CircleIcon
              style={{ color: grey[500] }}
              data-testid={`${result.id}-${result.result}`}
            />
          </Tooltip>
        );
      case 'error':
        return (
          <Tooltip title="error">
            <ErrorIcon
              style={{ color: result.optional ? grey[500] : purple[500] }}
              data-testid={`${result.id}-${result.result}`}
            />
          </Tooltip>
        );
      case 'wait':
        return (
          <Tooltip title="wait">
            <AccessTimeIcon data-testid={`${result.id}-${result.result}`} />
          </Tooltip>
        );

      default:
        return (
          <RadioButtonUncheckedIcon
            style={{
              color: grey[500],
            }}
          />
        );
    }
  } else {
    return (
      <RadioButtonUncheckedIcon
        style={{
          color: grey[500],
        }}
      />
    );
  }
};

export default ResultIcon;
