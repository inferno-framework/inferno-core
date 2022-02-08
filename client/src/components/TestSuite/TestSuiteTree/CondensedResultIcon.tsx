import React, { FC } from 'react';
import { Result } from 'models/testSuiteModels';
import FiberManualRecordIcon from '@mui/icons-material/FiberManualRecord';
import TripOriginIcon from '@mui/icons-material/TripOrigin';
import { Tooltip } from '@mui/material';
import { red, orange, green, purple, grey } from '@mui/material/colors';

export interface CondensedResultIconProps {
  result?: Result;
}

const CondensedResultIcon: FC<CondensedResultIconProps> = ({ result }) => {
  switch (result?.result) {
    case 'pass':
      return (
        <Tooltip title="passed">
          <FiberManualRecordIcon
            style={{
              color: result.optional ? green[100] : green[500],
              width: '.75em',
              height: '.75em',
            }}
            data-testid={`${result.id}-${result.result}`}
          />
        </Tooltip>
      );
    case 'fail':
      return (
        <Tooltip title="failed">
          <FiberManualRecordIcon
            style={{
              color: result.optional ? grey[500] : red[500],
              width: '0.75em',
              height: '0.75em',
            }}
            data-testid={`${result.id}-${result.result}`}
          />
        </Tooltip>
      );
    case 'cancel':
      return (
        <Tooltip title="cancel">
          <FiberManualRecordIcon
            style={{
              color: result.optional ? grey[500] : red[500],
              width: '0.75em',
              height: '0.75em',
            }}
            data-testid={`${result.id}-${result.result}`}
          />
        </Tooltip>
      );
    case 'skip':
      return (
        <Tooltip title="skipped">
          <FiberManualRecordIcon
            style={{
              color: result.optional ? grey[500] : orange[800],
              width: '0.75em',
              height: '0.75em',
            }}
            data-testid={`${result.id}-${result.result}`}
          />
        </Tooltip>
      );
    case 'omit':
      return (
        <Tooltip title="omitted">
          <FiberManualRecordIcon
            style={{ width: '0.75em', height: '0.75em' }}
            data-testid={`${result.id}-${result.result}`}
          />
        </Tooltip>
      );
    case 'error':
      return (
        <Tooltip title="error">
          <FiberManualRecordIcon
            style={{
              color: result.optional ? grey[500] : purple[500],
              width: '0.75em',
              height: '0.75em',
            }}
            data-testid={`${result.id}-${result.result}`}
          />
        </Tooltip>
      );
    default:
      return (
        <TripOriginIcon
          style={{
            color: grey[500],
            width: '0.6em',
            height: '0.6em',
          }}
        />
      );
  }
};

export default CondensedResultIcon;
