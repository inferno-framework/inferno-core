import React, { FC } from 'react';
import {
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Divider,
  Typography,
} from '@mui/material';
import { Requirement } from '~/models/testSuiteModels';
import RequirementContent from '~/components/TestSuite/Requirements/RequirementContent';

interface RequirementsModalProps {
  requirements: Requirement[];
  modalVisible: boolean;
  hideModal: () => void;
}

const RequirementsModal: FC<RequirementsModalProps> = ({
  requirements,
  hideModal,
  modalVisible,
}) => {
  return (
    <Dialog
      open={modalVisible}
      fullWidth={true}
      maxWidth="md"
      onClose={hideModal}
      data-testid="requestDetailModal"
      onKeyDown={(e) => e.stopPropagation()}
    >
      <DialogTitle>Specification Requirements</DialogTitle>
      <Divider />
      <DialogContent>
        <Typography fontWeight="bold">These scenarios test the following requirements:</Typography>
        {requirements.length > 0 ? (
          <RequirementContent requirements={requirements} view="dialog" />
        ) : (
          <Typography fontStyle="italic">No requirements found.</Typography>
        )}
      </DialogContent>
      <DialogActions>
        <Button
          color="secondary"
          variant="contained"
          data-testid="cancel-button"
          onClick={hideModal}
          sx={{ fontWeight: 'bold' }}
        >
          Close
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default RequirementsModal;
