import React, { FC } from 'react';
import { useNavigate } from 'react-router';
import { Alert, AlertColor, Box } from '@mui/material';
import { Message } from '~/models/testSuiteModels';
import { useTestSessionStore } from '~/store/testSession';
import useStyles from './styles';

interface TestSuiteMessagesProps {
  messages: Message[];
  testSuiteId?: string;
}

const TestSuiteMessages: FC<TestSuiteMessagesProps> = ({ messages, testSuiteId }) => {
  const navigate = useNavigate();
  const { classes } = useStyles();
  const viewOnly = useTestSessionStore((state) => state.viewOnly);

  const errorMessages = messages.filter((message) => message.type === 'error');
  const warningMessages = messages.filter((message) => message.type === 'warning');
  const infoMessages = messages.filter((message) => message.type === 'info');

  const alert = (severity: AlertColor, message: string) => (
    <Box className={classes.alertCursor}>
      <Alert
        tabIndex={0}
        severity={severity}
        variant="filled"
        onClick={() => {
          void navigate(`#${testSuiteId || ''}/config${viewOnly ? '/view' : ''}`);
        }}
        onKeyDown={(e) => {
          if (e.key === 'Enter') {
            void navigate(`#${testSuiteId || ''}/config${viewOnly ? '/view' : ''}`);
          }
        }}
        className={classes.alert}
      >
        <Box display="flex">
          <Box className={classes.alertMessage}>{message}</Box>
        </Box>
      </Alert>
    </Box>
  );

  return (
    <>
      {errorMessages.length > 0 &&
        alert(
          'error',
          errorMessages.length > 1
            ? `There are ${errorMessages.length} configuration errors that must be resolved.`
            : `There is 1 configuration error that must be resolved.`,
        )}
      {warningMessages.length > 0 &&
        alert(
          'warning',
          warningMessages.length > 1
            ? `There are ${warningMessages.length} configuration warnings.`
            : `There is 1 configuration warning.`,
        )}
      {infoMessages.length > 0 &&
        alert(
          'info',
          infoMessages.length > 1
            ? `There are ${infoMessages.length} configuration errors.`
            : `There is 1 configuration message.`,
        )}
    </>
  );
};

export default TestSuiteMessages;
