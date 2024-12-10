import {
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
} from '@mui/material';
import React, { FC } from 'react';
import Markdown from 'react-markdown';
import remarkGfm from 'remark-gfm';

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
          <Markdown remarkPlugins={[remarkGfm]}>{message || ''}</Markdown>
        </DialogContentText>
      </DialogContent>
      <DialogActions>
        <Button
          color="secondary"
          variant="contained"
          disableElevation
          onClick={cancelTestRun}
          data-testid="cancel-button"
          sx={{ fontWeight: 'bold' }}
        >
          Cancel
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default ActionModal;
