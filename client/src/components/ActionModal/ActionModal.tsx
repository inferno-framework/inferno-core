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
  cancelTest: () => void;
}

const ActionModal: FC<ActionModalProps> = ({ modalVisible, message, cancelTest }) => {
  return (
    <Dialog open={modalVisible} fullWidth={true} maxWidth="sm">
      <DialogTitle>User Action Required</DialogTitle>
      <DialogContent>
        <DialogContentText>
          <ReactMarkdown>{message ? message : ''}</ReactMarkdown>
        </DialogContentText>
      </DialogContent>
      <DialogActions>
        <Button color="primary" onClick={() => cancelTest()} data-testid="cancel-button">
          Cancel
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default ActionModal;
