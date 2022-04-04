import React, { FC } from 'react';
import { useHistory } from 'react-router-dom';
import { Alert, AlertColor, Box } from '@mui/material';
import { Message } from 'models/testSuiteModels';
import useStyles from './styles';

interface TestSuiteMessagesProps {
  messages: Message[];
  testSuiteId?: string;
}

const TestSuiteMessages: FC<TestSuiteMessagesProps> = ({ messages, testSuiteId }) => {
  const styles = useStyles();
  const history = useHistory();
  const errorMessages = messages.filter((message) => message.type === 'error');
  const warningMessages = messages.filter((message) => message.type === 'warning');
  const infoMessages = messages.filter((message) => message.type === 'info');

  const alert = (severity: AlertColor, message: string) => (
    <Box className={styles.alertCursor}>
      <Alert
        severity={severity}
        variant="filled"
        onClick={() => {
          history.push(`${history.location.pathname}#${testSuiteId || ''}/config`);
        }}
        className={styles.alert}
      >
        <Box sx={{ display: 'flex' }}>
          <Box className={styles.alertMessage}>{message}</Box>
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
            : `There is 1 configuration error that must be resolved.`
        )}
      {warningMessages.length > 0 &&
        alert(
          'warning',
          warningMessages.length > 1
            ? `There are ${warningMessages.length} configuration warnings.`
            : `There is 1 configuration warning.`
        )}
      {infoMessages.length > 0 &&
        alert(
          'info',
          infoMessages.length > 1
            ? `There are ${infoMessages.length} configuration errors.`
            : `There is 1 configuration message.`
        )}
    </>
  );
};

export default TestSuiteMessages;
