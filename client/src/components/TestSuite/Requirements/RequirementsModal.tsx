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
import { enqueueSnackbar } from 'notistack';
import { getTestSuiteRequirements } from '~/api/RequirementsApi';
import { Requirement, TestSuite } from '~/models/testSuiteModels';
// import useStyles from './styles';
import RequirementContent from './RequirementContent';

interface RequirementsModalProps {
  testSuite: TestSuite;
  modalVisible: boolean;
  hideModal: () => void;
}

const RequirementsModal: FC<RequirementsModalProps> = ({ testSuite, hideModal, modalVisible }) => {
  // const { classes } = useStyles();
  // const [requirements, setRequirements] = React.useState<Requirement[]>([]);
  const [filteredRequirements, setFilteredRequirements] = React.useState<Requirement[]>([]);
  const [triedFetchRequirements, setTriedFetchRequirements] = React.useState<boolean>(false);

  // const selectedValues = React.useMemo(
  //   () => allValues.filter((v) => v.selected),
  //   [allValues],
  // );

  // Fetch requirements from API
  if (!triedFetchRequirements) {
    getTestSuiteRequirements(testSuite.id)
      .then((result) => {
        if (result.length > 0) {
          // setRequirements(result);
          setFilteredRequirements(result);
        } else {
          enqueueSnackbar('Failed to fetch specification requirements', { variant: 'error' });
        }
      })
      .catch((e: Error) => {
        enqueueSnackbar(`Error fetching specification requirements: ${e.message}`, {
          variant: 'error',
        });
      });
    setTriedFetchRequirements(true);
  }

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
        <Typography variant="h5" component="p" fontWeight="bold" sx={{ mb: 2 }}>
          test
        </Typography>
        {filteredRequirements.length > 0 ? (
          <RequirementContent requirements={filteredRequirements} />
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
