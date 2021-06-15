import React, { FC, Fragment } from 'react';
import { Result } from 'models/testSuiteModels';
import { Tooltip } from '@material-ui/core';
import { green, red } from '@material-ui/core/colors';
import CheckIcon from '@material-ui/icons/Check';
import CancelIcon from '@material-ui/icons/Cancel';
import ErrorIcon from '@material-ui/icons/Error';
import { RedoOutlined } from '@material-ui/icons';
import RadioButtonUncheckedIcon from '@material-ui/icons/RadioButtonUnchecked';
export interface ResultIconProps {
  result?: Result;
}

const ResultIcon: FC<ResultIconProps> = ({ result }) => {
  if (result) {
    switch (result.result) {
      case 'pass':
        return (
          <Tooltip title="passed">
            <CheckIcon
              style={{ color: green[500] }}
              data-testid={`${result.id}-${result.result}`}
            />
          </Tooltip>
        );
      case 'fail':
        return (
          <Tooltip title="failed">
            <CancelIcon style={{ color: red[500] }} data-testid={`${result.id}-${result.result}`} />
          </Tooltip>
        );
      case 'skip':
        return (
          <Tooltip title="skipped">
            <RedoOutlined data-testid={`${result.id}-${result.result}`} />
          </Tooltip>
        );
      case 'omit':
        return (
          <Tooltip title="omitted">
            <RadioButtonUncheckedIcon data-testid={`${result.id}-${result.result}`} />
          </Tooltip>
        );
      case 'error':
        return (
          <Tooltip title="error">
            <ErrorIcon style={{ color: red[500] }} data-testid={`${result.id}-${result.result}`} />
          </Tooltip>
        );
      default:
        return <Fragment />;
    }
  } else {
    return <Fragment />;
  }
};

export default ResultIcon;
