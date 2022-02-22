import {
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
} from '@mui/material';
import React, { FC } from 'react';
import ReactMarkdown from 'react-markdown';

export interface ActionModalProps {
  modalVisible: boolean;
  message?: string;
  cancelTestRun: () => void;
}

const ActionModal: FC<ActionModalProps> = ({ modalVisible, message, cancelTestRun }) => {
  return (
    <Dialog open={modalVisible} fullWidth maxWidth="sm">
      <DialogTitle>User Action Required</DialogTitle>
      <DialogContent>
        <DialogContentText component="div">
          <ReactMarkdown>{message || ''}</ReactMarkdown>
        </DialogContentText>
      </DialogContent>
      <DialogActions>
        <Button color="primary" onClick={cancelTestRun} data-testid="cancel-button">
          Cancel
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default ActionModal;
