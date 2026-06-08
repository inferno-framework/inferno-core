import {
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  Typography,
} from '@mui/material';
import React, { FC, useEffect, useState } from 'react';
import Markdown from 'react-markdown';
import remarkGfm from 'remark-gfm';

export interface ActionModalProps {
  modalVisible: boolean;
  message?: string;
  cancelTestRun: () => void;
  waitTimeout?: string;
}

const ActionModal: FC<ActionModalProps> = ({
  modalVisible,
  message,
  cancelTestRun,
  waitTimeout,
}) => {
  const [secondsRemaining, setSecondsRemaining] = useState<number | null>(null);

  useEffect(() => {
    if (!modalVisible || !waitTimeout) {
      setSecondsRemaining(null);
      return;
    }

    const expiryTime = new Date(waitTimeout).getTime();

    const computeRemaining = () => Math.max(0, Math.floor((expiryTime - Date.now()) / 1000));

    setSecondsRemaining(computeRemaining());

    const interval = setInterval(() => {
      const remaining = computeRemaining();
      setSecondsRemaining(remaining);
      if (remaining === 0) clearInterval(interval);
    }, 1000);

    return () => clearInterval(interval);
  }, [modalVisible, waitTimeout]);

  const renderCountdown = () => {
    if (secondsRemaining === null) return null;

    if (secondsRemaining === 0) {
      return (
        <Typography variant="body2" sx={{ fontWeight: 'bold', color: 'error.main' }}>
          This test run has expired. Click CANCEL to continue the session.
        </Typography>
      );
    }

    return (
      <Typography variant="body2">
        {'This test run expires and will stop responding in '}
        <strong>{secondsRemaining} seconds.</strong>
      </Typography>
    );
  };

  return (
    <Dialog open={modalVisible} fullWidth maxWidth="sm">
      <DialogTitle>User Action Required</DialogTitle>
      <DialogContent>
        <DialogContentText component="div">
          <Markdown remarkPlugins={[remarkGfm]}>{message || ''}</Markdown>
        </DialogContentText>
      </DialogContent>
      <DialogActions
        sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', pl: 3 }}
      >
        {renderCountdown()}
        <Button
          color="secondary"
          variant="contained"
          disableElevation
          onClick={cancelTestRun}
          data-testid="cancel-button"
          sx={{ fontWeight: 'bold', flexShrink: 0 }}
        >
          Cancel
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default ActionModal;
