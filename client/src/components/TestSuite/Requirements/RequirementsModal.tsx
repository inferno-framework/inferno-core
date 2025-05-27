import React, { FC, useEffect } from 'react';
import {
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Divider,
  Typography,
} from '@mui/material';
import { enqueueSnackbar } from 'notistack';
import { getSingleRequirement } from '~/api/RequirementsApi';
import { Requirement, Runnable } from '~/models/testSuiteModels';
// import useStyles from './styles';
import RequirementContent from './RequirementContent';

interface RequirementsModalProps {
  runnable: Runnable;
  modalVisible: boolean;
  hideModal: () => void;
}

const RequirementsModal: FC<RequirementsModalProps> = ({ runnable, hideModal, modalVisible }) => {
  // const { classes } = useStyles();
  const [requirements, setRequirements] = React.useState<Requirement[]>([]);

  // Fetch requirements from API
  useEffect(() => {
    runnable.verifies_requirements?.forEach((requirement) => {
      getSingleRequirement(requirement)
        .then((result) => {
          if (result) {
            setRequirements([...requirements, result]);
          } else {
            enqueueSnackbar('Failed to fetch specification requirements', { variant: 'error' });
          }
        })
        .catch((e: Error) => {
          enqueueSnackbar(`Error fetching specification requirements: ${e.message}`, {
            variant: 'error',
          });
        });
    });
  }, []);

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
          <RequirementContent requirements={requirements} />
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
